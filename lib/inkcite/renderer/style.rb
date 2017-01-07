module Inkcite
  module Renderer
    class Style

      def initialize name, ctx, styles={}

        @name = name
        @ctx = ctx
        @styles = styles

      end

      def [] key
        @styles[key]
      end

      def []= key, val
        @styles[key] = val
      end

      def to_css allowed_prefixes=nil
        "#{@name} { #{to_inline_css(allowed_prefixes)} }"
      end

      def to_inline_css allowed_prefixes=nil

        # Inherit the list of allowed prefixes from the context if
        # none were provided.  Otherwise, make sure we're working
        # with an array.
        if allowed_prefixes.nil?
          allowed_prefixes = @ctx.prefixes
        else
          allowed_prefixes = [*allowed_prefixes]
        end

        # This will hold a copy of the key and values including
        # all keys with prefixes.
        _styles = {}

        # A reusable array indicating no prefixing is necessary.
        no_prefixes = ['']

        @styles.each_pair do |key, val|

          # Determine which list of prefixes are needed based on the
          # original key (e.g. :transform) - or use the list of
          # non-modifying prefixes.
          prefixes = if Inkcite::Renderer::Style.needs_prefixing?(key)
            allowed_prefixes
          else
            no_prefixes
          end

          # Iterate through each prefix and create a hybrid key.  Then
          # add the styles to the temporary list.
          prefixes.each do |prefix|
            prefixed_key = "#{prefix}#{key}".to_sym
            _styles[prefixed_key] = val
          end

        end

        Renderer.render_styles(_styles)
      end

      def to_s
        @name.blank? ? to_inline_css : to_css
      end

      def self.needs_prefixing? key
        PREFIXABLE_KEYS.include?(key.to_sym)
      end

      private

      # Array of CSS attributes that must be prefixed (e.g. transform and animation)
      PREFIXABLE_KEYS = [:animation, :transform]

    end
  end
end
