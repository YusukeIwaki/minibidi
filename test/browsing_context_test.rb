require 'minitest/autorun'
require 'minibidi'
require 'rack/test_server'
require 'sinatra/base'

class BrowsingContextTest < Minitest::Test
  def rackup(sinatra, &block)
    server = Rack::TestServer.new(
      app: sinatra,
      server: :webrick,
      Host: '127.0.0.1',
      Port: 3000)
    server.start_async
    server.wait_for_ready
    base_url = 'http://localhost:3000'

    begin
      block.call(base_url)
    ensure
      server.stop_async
      server.wait_for_stopped
    end
  end

  def test_reload
    calls = []
    sinatra = Class.new(Sinatra::Base) do
      get('/ping') { calls << Time.now ; 'pong' }
    end

    rackup(sinatra) do |base_url|
      Minibidi::Firefox.launch do |browser|
        context = browser.create_browsing_context
        context.navigate("#{base_url}/ping")
        sleep 0.5
        context.reload
        sleep 0.5
        assert_equal 2, calls.size
      end
    end
  end

  def test_activate
    Minibidi::Firefox.launch do |browser|
      browser.create_browsing_context do |context1|
        browser.create_browsing_context do |context2|
          context1.navigate("about:blank")
          context2.navigate("about:blank")
          sleep 0.5
          context1.activate
          sleep 0.5
          context2.activate
          sleep 0.5
        end
      end
    end
  end

  def test_back_forward
    calls = []
    sinatra = Class.new(Sinatra::Base) do
      3.times do |i|
        get("/#{i}") do
          calls << i
          <<~HTML
          <a href="/#{i+1}">click me</a>
          HTML
        end
      end
    end

    rackup(sinatra) do |base_url|
      Minibidi::Firefox.launch do |browser|
        context = browser.create_browsing_context
        context.navigate("#{base_url}/0")
        sleep 0.5
        2.times do
          context.default_realm.script_evaluate('document.querySelector("a").click()')
          sleep 0.5
        end
        context.traverse_history(-1) # -> 1
        sleep 0.5
        context.traverse_history(-1) # -> 0
        sleep 0.5
        context.reload # -> 0
        sleep 0.5
        context.traverse_history(2) # -> 2
        sleep 0.5
        context.reload # -> 2
        sleep 0.5

        assert_equal [0, 1, 2, 0, 2], calls
      end
    end
  end

  def test_input_click
    calls = []
    sinatra = Class.new(Sinatra::Base) do
      get('/') {
        <<~HTML
        <a href="/2" style="position: absolute; left: 0px; top: 0px; font-size: 20pt">XXXXX</a>
        <a href="/3" style="position: absolute; left: 0px; top: 0px; font-size: 20pt">YYYYY</a>
        HTML
      }
      get ('/2') { calls << '2 clicked' }
      get ('/3') { calls << '3 clicked' }
    end

    rackup(sinatra) do |base_url|
      Minibidi::Firefox.launch do |browser|
        context = browser.create_browsing_context
        context.navigate("#{base_url}/")
        sleep 0.5
        context.input.click(x: 10, y: 10)
        sleep 0.5
        assert_equal ['3 clicked'], calls
      end
    end
  end

  def test_input_press_key
    calls = []
    sinatra = Class.new(Sinatra::Base) do
      get('/') {
        <<~HTML
        <form method="post" action="/submit">
        <input id="input" name="input" type="text"/>
        </form>
        HTML
      }
      post('/submit') {
        calls << params
        redirect '/'
      }
    end

    rackup(sinatra) do |base_url|
      Minibidi::Firefox.launch do |browser|
        context = browser.create_browsing_context
        context.navigate("#{base_url}/")
        context.default_realm.script_evaluate('document.querySelector("#input").focus()')
        context.input.press_key('a')
        context.input.press_key('B')
        context.input.press_key('Enter')
        sleep 0.5
        context.default_realm.script_evaluate('document.querySelector("#input").focus()')
        context.input.press_key('🍰')
        context.input.press_key('Enter')
        sleep 0.5
        assert_equal [{'input' => 'aB'}, {'input' => '🍰'}], calls
      end
    end
  end

  def test_input_while_pressing_key
    calls = []
    sinatra = Class.new(Sinatra::Base) do
      get('/') {
        <<~HTML
        <form method="post" action="/submit">
        <div><textarea name="textarea"></textarea></div>
        <input type="submit"/>
        </form>
        HTML
      }
      post('/submit') {
        calls << params
        redirect '/'
      }
    end

    rackup(sinatra) do |base_url|
      Minibidi::Firefox.launch do |browser|
        context = browser.create_browsing_context
        context.navigate("#{base_url}/")
        context.default_realm.script_evaluate('document.querySelector("textarea").focus()')
        context.input.while_pressing_key('Shift') do
          context.input.press_key('a')
          context.input.type_text('bcde')
        end
        context.input.press_key('Tab')
        context.input.press_key('Enter')
        sleep 0.5
        context.default_realm.script_evaluate('document.querySelector("textarea").focus()')
        context.input.type_text('bcde')
        context.input.while_pressing_key('CtrlOrMeta') do
          context.input.press_key('a')
        end
        context.input.type_text('bcde')
        context.input.press_key('Tab')
        context.input.press_key('Enter')
        sleep 0.5
        assert_equal [{'textarea' => 'ABCDE'}, {'textarea' => 'bcde'}], calls
      end
    end
  end

  def test_realm_script_evaluate
    Minibidi::Firefox.launch do |browser|
      context = browser.create_browsing_context
      assert_equal 3, context.default_realm.script_evaluate('1 + 2')
      assert_equal 3.14159, context.default_realm.script_evaluate('Math.PI').round(5)
      assert_equal [3, "4", 5.0, { 'a' => 3, 'b' => "4" }], context.default_realm.script_evaluate('[3, "4", 5.0, { a: 3, b: "4" }]')
      assert_equal({ 'a' => 3, 'b' => "4", 'c' => [] }, context.default_realm.script_evaluate('({ a: 3, b: "4", c: [] })'))
      assert_equal Date.new(2021, 1, 1), context.default_realm.script_evaluate('new Date("2021-01-01")')
      assert_equal(/A*b/mi, context.default_realm.script_evaluate('new RegExp("A*b", "mi")'))
      assert_equal(/A*b/m, context.default_realm.script_evaluate('new RegExp("A*b", "m")'))
      assert_equal(/A*b/, context.default_realm.script_evaluate('new RegExp("A*b", "g")'))
      assert_nil context.default_realm.script_evaluate('undefined')
      assert_nil context.default_realm.script_evaluate('null')
      assert_equal 42, context.default_realm.script_evaluate('Promise.resolve().then(() => 42)')

      err = assert_raises(Minibidi::Realm::ScriptEvaluationError) { context.default_realm.script_evaluate('aaa') }
      assert_match /aaa is not defined/, err.message
    end
  end
end
