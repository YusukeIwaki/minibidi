require 'minitest/autorun'
require 'minibidi'

class ExampleTest < Minitest::Test
  def test_firefox_example
    Minibidi::Firefox.launch do |browser|
      context = browser.create_browsing_context
      context.navigate("https://github.com/YusukeIwaki")
      data = context.capture_screenshot(origin: :viewport, format: { type: :png })

      open('YusukeIwaki.png', 'wb') do |f|
        f.write(data)
      end
    end
  end
end
