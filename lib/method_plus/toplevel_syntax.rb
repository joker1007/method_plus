module MethodPlus
  module ToplevelSyntax
    refine Kernel do
      def _any
        MethodPlus::Placeholder.new
      end
    end
  end
end
