module Inkcite
  class Animation
    class Keyframe

      attr_reader :percent, :style

      # Ending percentage the animation stays at this keyframe.  For
      # example, a keyframe that starts at 20% and has a duration
      # of 19.9% would render as 25%, 39.9% { ... }
      attr_accessor :duration

      # Alternative to duration, the ending percentage
      attr_accessor :end_percent

      def initialize percent, ctx, styles={}

        # Animation percents are always rounded to the nearest whole number.
        @percent = percent
        @end_percent = nil
        @duration = nil

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

        ends_at = calc_ends_at
        css << ", #{ends_at}%" if ends_at

        css << ' { '
        css << @style.to_inline_css(prefix)
        css << ' }'
        css
      end

      private

      # Returns the percent at which the animation keyframe ends
      # based on either end_percent (preferred) or duration (deprecated)
      # being set.  Will return nil if neither is present.
      def calc_ends_at
        ends_at = if @end_percent
          @end_percent
        elsif @duration
          (@percent + @duration).round(1)
        end

        # Ensure that the ending percentage never exceeds 100%
        ends_at = 100 if ends_at && ends_at >= 100.0

        ends_at
      end

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
  end
end
