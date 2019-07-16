# MethodPlus

Method class extentions for `.:method_name` syntax.

# Example

```ruby
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

foo = Foo.new

promise1 = foo.:slowly_foo.async(sleep_time: 0.1) # return Concurrent::Promises::Future by concurrent-ruby
promise1.value # => "foo"

using MethodPlus::ToplevelSyntax
new_pr = foo.:with_args.partial(_any, b: true) # => return Proc
new_pr.call(0.1) # => [0.1, true, true]
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'method_plus'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install method_plus

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/method_plus.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
