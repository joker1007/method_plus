require "concurrent"
require "debug_inspector"

module MethodPlus
  class Placeholder
  end

  module CoreExt
    def async(*args, &block)
      check_arity(*args)

      Concurrent::Promises.future_on(:io, *args) do |*args|
        call(*args, &block)
      end
    end

    def partial(*args, **kw, &block)
      ->(*args2, **kw2, &block2) do
        placeholder_idx = 0
        new_args = args.each_with_object([]) do |a, arr|
          if a.is_a?(MethodPlus::Placeholder)
            if (args2.size - 1) >= placeholder_idx
              arr << args2[placeholder_idx].tap { placeholder_idx += 1 }
            end
          else
            arr << a
          end
        end

        new_kw = kw.map { |k, v|
          case [k, v]
          in [_, MethodPlus::Placeholder]
            if kw2.key?(k)
              [k, kw2[k]]
            end
          else
            [k, v]
          end
        }.compact.to_h

        new_block = block2 || block
        call(*new_args, **new_kw, &new_block)
      end
    end

    def defer(*args, &block)
      iseq = nil
      stack_level = 0
      params = {Thread.current => [args, block]}
      current_thread = Thread.current
      RubyVM::DebugInspector.open do |dc|
        iseq = dc.frame_iseq(2)
      end

      events = iseq.to_a[9] == :method ? [:return] : [:b_call, :b_return]

      trace = TracePoint.new(*events) do |tp|
        next unless current_thread == Thread.current

        if tp.event == :b_call
          stack_level += 1
          next
        end

        if tp.event == :b_return && stack_level > 0
          stack_level -= 1
          next
        end

        begin
          t = Thread.current["defer_method_#{object_id}"]
          next unless t
          t.disable
          a, b = params[Thread.current]
          call(*a, &b)
          Thread.current["defer_method_#{object_id}"] = nil
        ensure
          t.disable if t&.enabled?
        end
      end
      Thread.current["defer_method_#{object_id}"] = trace
      trace.enable(target: iseq)
    end

    private

    def check_arity(*args)
      if is_a?(Proc) && !lambda?
        true
      end
      # cannot detect cfunc args
      true if parameters == [[:rest]]

      req_size = 0
      opt_size = 0
      has_rest = false
      has_kw = false
      keyreqs = []

      parameters.each do |pr|
        case pr
        in [:req, _]
          req_size += 1
        in [:opt, _]
          opt_size += 1
        in [:rest, _]
          has_rest = true
        in [:keyreq, name]
          has_kw = true
          keyreqs << name
        in [:key, _]
          has_kw = true
        in [:keyrest, _]
          has_kw = true
        else
        end
      end

      args_range = has_rest ? (req_size..) : (req_size..req_size + opt_size + (has_kw ? 1 : 0))

      missing_keys = []
      if args.last.is_a?(Hash) && has_kw
        last = args.pop
        missing_keys = keyreqs.reject do |k|
          last.key?(k)
        end
      else
        missing_keys = keyreqs
      end

      if !args_range.cover?(args.size) || !missing_keys.empty?
        error_message = "wrong number of arguments"
        error_message_details = []
        if !args_range.cover?(args.size)
          if opt_size == 0
            error_message_details << "given #{args.size}, expected #{req_size}"
          else
            error_message_details << "given #{args.size}, expected #{args_range}"
          end
        end
        if !missing_keys.empty?
          error_message_details << "required keyword #{missing_keys.map(&:to_s).join(", ")}"
        end
        raise ArgumentError.new("#{error_message} (#{error_message_details.join(", ")})")
      end
    end
  end
end

Method.prepend(MethodPlus::CoreExt)
Proc.prepend(MethodPlus::CoreExt)
