require_relative 'composite_animation'

module Inkcite
  class Animation

    class Keyframe

      attr_reader :percent, :style

      # Ending percentage the animation stays at this keyframe.  For
      # example, a keyframe that starts at 20% and has a duration
      # of 19.9% would render as 25%, 39.9% { ... }
      attr_accessor :duration

      def initialize percent, ctx, styles={}

        # Animation percents are always rounded to the nearest whole number.
        @percent = percent.round(0)
        @duration = 0

        # Instantiate a new Style for this percentage.
        @style = Inkcite::Renderer::Style.new(nil, ctx, styles)

      end

      def [] key
        @style[key]
      end

      def []= key, val
        @style[key] = val
      end

      # For style chaining - e.g. keyframe.add(:key1, 'val').add(:key)
      def add key, val
        @style[key] = val
        self
      end

      # Appends a value to an existing key
      def append key, val

        @style[key] ||= ''
        @style[key] << ' ' unless @style[key].blank?
        @style[key] << val

      end

      def add_with_prefixes key, val, ctx

        ctx.prefixes.each do |prefix|
          _key = "#{prefix}#{key}".to_sym
          self[_key] = val
        end

        self
      end

      def to_css prefix
        css = "#{@percent}%"
        css << ", #{@percent + @duration.to_f}%" if @duration > 0
        css << ' { '
        css << @style.to_inline_css(prefix)
        css << ' }'
        css
      end

      private

      # Creates a copy of the array of styles with the appropriate
      # properties (e.g. transform) prefixed.
      def get_prefixed_styles prefix

        _styles = {}

        @styles.each_pair do |key, val|
          key = "#{prefix}#{key}".to_sym if Inkcite::Renderer::Style.needs_prefixing?(key)
          _styles[key] = val
        end

        _styles
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
