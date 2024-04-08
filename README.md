# minibidi: Mini WebDriver BiDi binding for Ruby

```ruby
require 'minibidi'

Minibidi::Firefox.launch do |browser|
  context = browser.create_browsing_context
  context.navigate("https://github.com/YusukeIwaki")
  data = context.capture_screenshot(origin: :viewport, format: { type: :png })

  open('YusukeIwaki.png', 'wb') do |f|
    f.write(data)
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minibidi'
```

And then execute `bundle install`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
