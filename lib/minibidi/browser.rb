require 'async'
require 'async/variable'

module Minibidi
  class Browser
    def initialize(async_websocket_connection)
      @websocket = async_websocket_connection
      @debug_protocol = %w[1 true].include?(ENV['DEBUG'])

      Async do
        while data = async_websocket_connection.read
          if message = Protocol::WebSocket::JSONMessage.wrap(data)
            handle_received_message_from_websocket(message.to_h)
          end
        end
      end

      bidi_call_async('session.new', {
        capabilities: {
          alwaysMatch: {
            acceptInsecureCerts: false,
            webSocketUrl:true,
          },
        },
      }).wait
    end

    def create_browsing_context(&block)
      res = bidi_call_async('browsingContext.create', { type: :tab, userContext: :default }).wait
      browsing_context = BrowsingContext.new(self, res[:context])
      if block
        begin
          block.call(browsing_context)
        ensure
          browsing_context.close
        end
      else
        browsing_context
      end
    end

    def close
      bidi_call_async('browser.close').wait
    end

    def bidi_call_async(method_, params = {})
      with_message_id do |message_id|
        Async do
          @message_results[message_id] = Async::Variable.new

          send_message_to_websocket({
            id: message_id,
            method: method_,
            params: params,
          })

          value = @message_results[message_id].value
          if value.is_a?(ErrorData)
            raise value.to_error
          else
            value
          end
        end
      end
    end

    private

    def with_message_id(&block)
      unless @message_id
        @message_id = 1
        @message_results = {}
      end

      message_id = @message_id
      @message_id += 1
      block.call(message_id)
    end

    def send_message_to_websocket(payload)
      debug_print_send(payload)
      message = Protocol::WebSocket::JSONMessage.generate(payload)
      message.send(@websocket)
      @websocket.flush
    end

    def handle_received_message_from_websocket(payload)
      debug_print_recv(payload)

      if payload[:id]
        if variable = @message_results.delete(payload[:id])
          case payload[:type]
          when 'success'
            variable.resolve(payload[:result])
          when 'error'
            variable.resolve(ErrorData.parse(payload))
          end
        end
      end
    end

    class ErrorData < Data.define(:type, :message, :stacktrace)
      def self.parse(payload)
        # {:type=>"error", :id=>1, :error=>"invalid argument", :message=>"method: string value expected", :stacktrace=>"RemoteError@chrome://remote/content/shared/RemoteError.sys.mjs:8:8\nWebDriverError@chrome://remote/content/shared/webdriver/Errors.sys.mjs:193:5\nInvalidArgumentError@chrome://remote/content/shared/webdriver/Errors.sys.mjs:384:5\nassert.that/<@chrome://remote/content/shared/webdriver/Assert.sys.mjs:485:13\nassert.string@chrome://remote/content/shared/webdriver/Assert.sys.mjs:385:53\nonPacket@chrome://remote/content/webdriver-bidi/WebDriverBiDiConnection.sys.mjs:172:19\nonMessage@chrome://remote/content/server/WebSocketTransport.sys.mjs:127:18\nhandleEvent@chrome://remote/content/server/WebSocketTransport.sys.mjs:109:14\n"}
        new(
          type: payload[:error],
          message: payload[:message],
          stacktrace: payload[:stacktrace].split("\n"),
        )
      end

      def to_error
        Error.new("#{type}: #{message}\n#{stacktrace.join("\n")}")
      end
    end

    class Error < StandardError ; end

    def debug_print_send(hash)
      return unless @debug_protocol

      puts "SEND > #{hash}"
    end

    def debug_print_recv(hash)
      return unless @debug_protocol

      puts "RECV < #{hash}"
    end
  end
end
