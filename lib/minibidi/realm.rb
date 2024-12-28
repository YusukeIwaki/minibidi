module Minibidi
  class Realm
    def initialize(browsing_context:, id:, origin:, type: nil)
      @browsing_context = browsing_context
      @id = id
      @origin = origin
      @type = type
    end

    class ScriptEvaluationError < StandardError ; end

    def script_evaluate(expression)
      result = @browsing_context.send(:bidi_call_async, 'script.evaluate', {
        expression: expression,
        target: { realm: @id },
        awaitPromise: true,
      }).wait

      if result[:type] == 'exception'
        raise ScriptEvaluationError.new(result[:exceptionDetails][:text])
      end

      deserialize(result[:result])
    end

    attr_reader :type

    private

    def deserialize(result)
      # ref: https://github.com/puppeteer/puppeteer/blob/puppeteer-v23.5.3/packages/puppeteer-core/src/bidi/Deserializer.ts#L21
      # Converted using ChatGPT 4o
      case result[:type]
      when 'array'
        result[:value]&.map { |value| deserialize(value) }
      when 'set'
        result[:value]&.each_with_object(Set.new) do |value, acc|
          acc.add(deserialize(value))
        end
      when 'object'
        result[:value]&.each_with_object({}) do |tuple, acc|
          key, value = tuple
          acc[key] = deserialize(value)
        end
      when 'map'
        result[:value]&.each_with_object({}) do |tuple, acc|
          key, value = tuple
          acc[key] = deserialize(value)
        end
      when 'promise'
        {}
      when 'regexp'
        flags = 0
        result[:value][:flags]&.each_char do |flag|
          case flag
          when 'm'
            flags |= Regexp::MULTILINE
          when 'i'
            flags |= Regexp::IGNORECASE
          end
        end
        Regexp.new(result[:value][:pattern], flags)
      when 'date'
        Date.parse(result[:value])
      when 'undefined'
        nil
      when 'null'
        nil
      when 'number', 'bigint', 'boolean', 'string'
        result[:value]
      else
        raise ArgumentError, "Unknown type: #{result[:type]}"
      end
    end
  end
end
