module Inkcite
  class Animation

    # A collection of animations assigned to a single element.
    class Composite

      def initialize
        @animations = []
      end

      def << animation
        @animations << animation
      end

      def to_keyframe_css
        @animations.collect(&:to_keyframe_css).join("\n")
      end

      def to_s

        # Render each of the animations in the collection and join them
        # in a single, comma-delimited string.
        @animations.collect(&:to_s).join(', ')

      end

    end

    # Infinite iteration count
    INFINITE = 'infinite'

    # Timing functions
    LINEAR = 'linear'
    EASE = 'ease'
    EASE_IN = 'ease-in'
    EASE_IN_OUT = 'ease-in-out'
    EASE_OUT = 'ease-out'

    # Animation name, view context and array of keyframes
    attr_reader :name, :ctx

    attr_accessor :duration, :timing_function, :delay, :iteration_count

    def initialize name, ctx
      @name = name
      @ctx = ctx

      # Default values for the animation's properties
      @duration = 1
      @delay = 0
      @iteration_count = INFINITE
      @timing_function = LINEAR

      # Initialize the keyframes
      @keyframes = []

    end

    def add_keyframe percent, styles={}
      keyframe = Keyframe.new(percent, @ctx, styles)

      @keyframes << keyframe

      keyframe
    end

    # Returns true if this animation is blank - e.g. it has no keyframes.
    def blank?
      @keyframes.blank?
    end

    def to_keyframe_css

      css = ''

      # Sort the keyframes by percent in ascending order.
      sorted_keyframes = @keyframes.sort { |kf1, kf2| kf1.percent <=> kf2.percent }

      # Iterate through each prefix and render a set of keyframes
      # for each.
      @ctx.prefixes.each do |prefix|
        css << "@#{prefix}keyframes #{@name} {\n"
        css << sorted_keyframes.collect { |kf| kf.to_css(prefix) }.join("\n")
        css << "\n}\n"
      end

      css

    end

    # Renders this Animation declaration in the syntax defined here
    # https://developer.mozilla.org/en-US/docs/Web/CSS/animation
    # e.g. "3s ease-in 1s 2 reverse both paused slidein"
    def to_s

      # The desired format is: duration | timing-function | delay |
      # iteration-count | direction | fill-mode | play-state | name
      # Although currently not all attributes are supported.
      css = [
          seconds(@duration),
          @timing_function
      ]

      css << seconds(@delay) if @delay > 0

      css << @iteration_count

      css << @name

      css.join(' ')
    end

    private

    def seconds val
      "#{val}s"
    end

  end
end
