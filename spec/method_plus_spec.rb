RSpec.describe MethodPlus do
  using MethodPlus::ToplevelSyntax

  class Foo
    def slowly_foo(sleep_time: 1)
      sleep sleep_time
      "foo"
    end

    def hoge(a, b, c = nil, *rest)
    end

    def with_args(a, b:, c: true, **h)
      sleep a
      [a, b, c]
    end
  end

  it "can asynchronize any methods and procs" do
    foo = Foo.new

    promise1 = foo.:slowly_foo.async(sleep_time: 0.1)
    expect(promise1.value).to eq("foo")

    promise2 = foo.:with_args.async(0.1, b: true)
    expect(promise2.value).to eq([0.1, true, true])

    expect { foo.:with_args.async(1) }.to raise_error(ArgumentError)
    expect { foo.:with_args.async(b: true) }.to raise_error(ArgumentError)

   pr = ->(a) do
     sleep a
     "lambda"
   end

   expect(pr.async(0.1).value).to eq("lambda")
   expect { pr.async() }.to raise_error(ArgumentError)
  end

  it "enable any methods applyable partially" do
    foo = Foo.new

    pr = foo.:with_args.partial(MethodPlus::Placeholder.new, b: true)
    expect(pr.call(0.1)).to eq([0.1, true, true])
    expect { pr.call() }.to raise_error(ArgumentError)

    pr = foo.:with_args.partial(0.1, b: MethodPlus::Placeholder.new)
    expect(pr.call(b: 2)).to eq([0.1, 2, true])

    expect { pr.call(c: 2) }.to raise_error(ArgumentError)

    pr = foo.:with_args.partial(0.1, b: _any)
    expect(pr.call(b: 2)).to eq([0.1, 2, true])

    lambda_proc = ->(a, b:, c: true) do
      [a, b, c]
    end

    lambda_proc = foo.:with_args.partial(0.1, b: _any)
    expect(lambda_proc.call(b: 2)).to eq([0.1, 2, true])
  end
end
