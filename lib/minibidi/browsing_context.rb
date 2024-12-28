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

    def input
      Input.new(self)
    end

    def activate
      bidi_call_async('browsingContext.activate').wait
    end

    def capture_screenshot(origin: nil, format: nil, clip: nil)
      result = bidi_call_async('browsingContext.captureScreenshot', {
        origin: origin,
        format: format,
        clip: clip,
      }.compact).wait

      Base64.strict_decode64(result[:data])
    end

    def close(prompt_unload: nil)
      bidi_call_async('browsingContext.close', {
        promptUnload: prompt_unload,
      }.compact).wait
    end

    def reload(ignore_cache: nil, wait: nil)
      bidi_call_async('browsingContext.reload', {
        ignoreCache: ignore_cache,
        wait: wait,
      }.compact).wait
    end

    def set_viewport(width:, height:, device_pixel_ratio: nil)
      bidi_call_async('browsingContext.setViewport', {
        viewport: {
          width: width,
          height: height,
        },
        devicePixelRatio: device_pixel_ratio,
      }.compact).wait
    end

    def traverse_history(delta)
      bidi_call_async('browsingContext.traverseHistory', {
        delta: delta,
      }).wait
    end

    private

    def bidi_call_async(method_, params = {})
      @browser.bidi_call_async(method_, params.merge({ context: @context_id }))
    end
  end
end
