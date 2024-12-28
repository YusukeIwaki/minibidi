module Minibidi
  class KeyboardActionQueue
    def initialize
      @actions = []
    end

    def to_a
      @actions
    end

    def pause(duration)
      @actions << { type: 'pause', duration: duration }
    end

    def key_down(value)
      @actions << { type: 'keyDown', value: value }
    end

    def key_up(value)
      @actions << { type: 'keyUp', value: value }
    end
  end
end
