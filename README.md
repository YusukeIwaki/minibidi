# Mini BiDi: WebDriver BiDi playground

```ruby
MiniBiDi::Firefox.launch do |browser|
  context = browser.create_browsing_context
  context.navigate("https://github.com/YusukeIwaki")
  data = context.capture_screenshot(origin: :viewport, format: { type: :png })

  open('YusukeIwaki.png', 'wb') do |f|
    f.write(Base64.strict_decode64(data))
  end
end
```
