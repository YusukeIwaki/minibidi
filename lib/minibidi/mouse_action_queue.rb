module Minibidi
  class MouseActionQueue
    def initialize
      @actions = []
    end

    def to_a
      @actions
    end

    def pause(duration)
      @actions << { type: 'pause', duration: duration }
    end

    # button: 0 for left, 1 for middle, 2 for right
    def pointer_down(button:)
      @actions << { type: 'pointerDown', button: button }
    end

    def pointer_move(x:, y:, duration: nil)
      @actions << { type: 'pointerMove', x: x, y: y, duration: duration }.compact
    end

    # button: 0 for left, 1 for middle, 2 for right
    def pointer_up(button:)
      @actions << { type: 'pointerUp', button: button }
    end
  end
end
