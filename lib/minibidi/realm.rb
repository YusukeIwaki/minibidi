module Minibidi
  class Realm
    def initialize(browsing_context:, id:, origin:, type: nil)
      @browsing_context = browsing_context
      @id = id
      @origin = origin
      @type = type
    end

    def script_evaluate(expression)
      @browsing_context.send(:bidi_call_async, 'script.evaluate', {
        expression: expression,
        target: { realm: @id },
        awaitPromise: true,
      }).wait
    end

    attr_reader :type
  end
end
