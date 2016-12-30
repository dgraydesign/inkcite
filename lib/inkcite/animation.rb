module Inkcite
  module Animation

    class Keyframe

      attr_reader :percent

      def initialize percent, styles={}
        # Animation percents are always rounded to the nearest whole number.
        @percent = percent.round(0)
        @styles = styles
      end

      def [] key
        @styles[key]
      end

      def []= key, val
        @styles[key] = val
      end

      def add key, val
        self[key] = val
        self
      end

      def add_with_prefixes key, val, ctx

        Animation.get_prefixes(ctx).each do |prefix|
          _key = "#{prefix}#{key}".to_sym
          self[_key] = val
        end
        self
      end

      def to_s

        css = ''
        css << "  #{@percent}%"
        css << ' ' * (7 - css.length)
        css << '{ '
        css << Renderer.render_styles(@styles)
        css << ' }'

        css
      end

    end

    class Keyframes

      def initialize name, context
        @name = name
        @ctx = context
        @keyframes = []
      end

      def << keyframe
        @keyframes << keyframe
      end

      def add_keyframe percent, styles
        self << Keyframe.new(percent, styles)
      end

      def to_s

        css = ''

        keyframe_css = @keyframes.sort { |kf1,kf2| kf1.percent <=> kf2.percent }.collect(&:to_s).join("\n")

        prefixes = Animation.get_prefixes(@ctx)

        prefixes.each do |prefix|
          css << "@#{prefix}keyframes #{@name} {\n"
          css << keyframe_css
          css << "\n}\n"
        end

        css
      end

    end

    def self.get_prefixes ctx
      ALL_BROWSERS
    end

    # True if we're limiting the animation to webkit only.  In development
    # or in the browser version of the email, the animation should be as
    # compatible as possible but in all other cases it should be webkit only.
    def self.webkit_only? ctx
      false #&& !(ctx.development? || ctx.browser?)
    end

    # Renders the CSS with the appropriate browser prefixes based
    # on whether or not this version of the email is webkit only.
    def self.with_browser_prefixes css, ctx, opts={}

      indentation = opts[:indentation] || ''

      # Convert an integer indentation value into that number of spaces.
      indentation = ' ' * indentation if indentation.is_a?(Integer)

      separator = opts[:separator] || "\n"

      # Determine which prefixes will be applied.
      browser_prefixes = webkit_only?(ctx) ? WEBKIT_BROWSERS : ALL_BROWSERS

      # This will hold the completed CSS with all prefixes applied.
      _css = ''

      # Iterate through the prefixes and apply them with the indentation
      # and CSS declaration with line breaks.
      browser_prefixes.each do |prefix|
        _css << indentation
        _css << prefix
        _css << css
        _css << separator
      end

      _css
    end

    private


    # Static arrays with browser prefixes.  Turns out that Firefox, IE and Opera
    # don't require a prefix so to target everything we need the non-prefixed version
    # (hence the blank entry) plus the webkit prefix.
    WEBKIT_BROWSERS = ['-webkit-']
    ALL_BROWSERS = [''] + WEBKIT_BROWSERS

  end
end
