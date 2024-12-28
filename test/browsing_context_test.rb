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
end
