require 'base64'

module Minibidi
  class BrowsingContext
    def initialize(browser, context_id)
      @browser = browser
      @context_id = context_id
    end

    def navigate(url, wait: :interactive)
      bidi_call_async('browsingContext.navigate', {
        url: url,
        wait: wait,
      }.compact).wait
    end

    def realms
      result = bidi_call_async('script.getRealms').wait
      result[:realms].map do |realm|
        Realm.new(
          browsing_context: self,
          id: realm[:realm],
          origin: realm[:origin],
          type: realm[:type],
        )
      end
    end

    def default_realm
      realms.find { |realm| realm.type == 'window' }
    end

    def capture_screenshot(origin: nil, format: nil, clip: nil)
      result = bidi_call_async('browsingContext.captureScreenshot', {
        origin: origin,
        format: format,
        clip: clip,
      }.compact).wait

      Base64.strict_decode64(result[:data])
    end

    def reload(ignore_cache: nil, wait: nil)
      bidi_call_async('browsingContext.reload', {
        ignoreCache: ignore_cache,
        wait: wait,
      }.compact).wait
    end

    private

    def bidi_call_async(method_, params = {})
      @browser.bidi_call_async(method_, params.merge({ context: @context_id }))
    end
  end
end
