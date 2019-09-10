RSpec.describe MethodPlus do
  using MethodPlus::ToplevelSyntax

  class Foo
    def slowly_foo(sleep_time: 1, word: "foo")
      sleep sleep_time
      word
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

   promise3 = [1, 2, 3].:map.async { |n| n * 2 }
   expect(promise3.value).to eq([2, 4, 6])
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

    # no placeholder arg
    pr = foo.:with_args.partial(1, b: 2, c: false)
    expect(pr.call).to eq([1, 2, false])
  end

  def meth1(i)
    @results["meth1"] ||= []
    "after2".:tap.defer { |v| @results["meth1"] << v }
    "after1".:tap.defer { |v| @results["meth1"] << v }
    @results["meth1"] << "before"
    [1, 2, 3].each do |n|
      "inner_after#{n}".:tap.defer { |v| @results["meth1"] << v }
      [1].map { |i| i * 2 }
      @results["meth1"] << "inner_before#{n}"
    end
  end

  it do
    @results = {}
    meth1(1)
    expect(@results["meth1"][0]).to eq("before")
    expect(@results["meth1"][1]).to eq("inner_before1")
    expect(@results["meth1"][2]).to eq("inner_after1")
    expect(@results["meth1"][3]).to eq("inner_before2")
    expect(@results["meth1"][4]).to eq("inner_after2")
    expect(@results["meth1"][5]).to eq("inner_before3")
    expect(@results["meth1"][6]).to eq("inner_after3")
    expect(@results["meth1"][7]).to eq("after1")
    expect(@results["meth1"][8]).to eq("after2")
  end
end
