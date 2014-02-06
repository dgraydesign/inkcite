module Inkcite
  module Renderer
    class Responsive < Base

      BUTTON  = 'button'
      DROP    = 'drop'
      FILL    = 'fill'
      HIDE    = 'hide'

      class Rule

        attr_reader :declarations
        attr_reader :klass

        def initialize tags, klass, declarations, active=true
          @klass = klass
          @declarations = declarations

          @tags = Set.new [*tags]

          # By default, a rule isn't considered active until it has
          # been marked used.  This allows the view to declare built-in
          # styles (such as hide or stack) that don't show up in the
          # rendered HTML unless the author references them.
          @active = active

        end

        def << tag
          @tags << tag
        end

        def activate!
          @active = true
        end

        def active?
          @active
        end

        def include? tag
          universal? || @tags.include?(tag)
        end

        def to_css

          rule = ""

          att_selector = "[class~=#{Renderer.quote(@klass)}]"

          if universal?

            # Only the attribute selector is needed when the rule is universal.
            # http://www.w3.org/TR/CSS2/selector.html#universal-selector
            rule << att_selector

          else

            # Create an attribute selector that targets each tag.
            @tags.sort.each do |tag|
              rule << ',' unless rule.blank?
              rule << tag
              rule << att_selector
            end

          end

          rule << " { "
          if @declarations.is_a?(Hash)
            rule << Renderer.render_styles(@declarations)
          elsif @declarations.is_a?(Array)
            rule << @declarations.join(' ')
          else
            rule << @declarations.to_s
          end
          rule << " }"

          rule
        end

        def universal?
          @tags.include?(UNIVERSAL)
        end

      end

      def mix_responsive tag, opt, att, sty, ctx, klass=nil

        # If a forced (override) klass was not provided by the caller then
        # check to see if a mobile klass name (e.g. hide) has been defined
        # on this element.
        klass ||= opt[:mobile]

        # Check to see if a mobile style (e.g. "mobile-style='background-color: #ff0;'")
        # has been declared for this element.
        declarations = opt[MOBILE_STYLE]

        # Will hold the Responsive::Rule that exists (or will be created) that
        # matches the tag and style declarations targeting mobile devices.
        rule = nil

        if klass.blank?

          # Nothing mobile-specific about this tag so quick abort.
          return if declarations.blank?

          # If no klass was specified, check to see if any previously defined rule matches
          # the style declarations.  If so, we'll reuse that rule and apply the klass
          # to this object to avoid unnecessary duplication in the HTML.
          rule = ctx.responsive_styles.detect { |r| r.declarations == declarations }

          # Generate a unique class name for this style if it has not already been declared.
          # These are of the form m001, etc.  Redability is not important because it's
          # dynamically generated and referenced.
          klass = "m%03d" % ctx.unique_id(:m)

        else

          # Check to see if there is already a rule that specifically matches this klass
          # and tag combination - e.g. td.hide
          rule = ctx.responsive_styles.detect { |r| klass == r.klass && r.include?(tag) }
          if rule.nil?

            # If no rule was found then find the first that matches the klass.
            rule = ctx.responsive_styles.detect { |r| klass == r.klass }

            if declarations.blank?

              # If no rule was found and the declaration is blank then we have
              # an unknown mobile behavior.
              if rule.nil?
                ctx.error 'Undefined mobile behavior - are you missing a mobile-style declaration?', { :tag => tag, :mobile => klass }
                return false
              end

            elsif rule && declarations != rule.declarations

              # If an existing rule if found but the author has declared styles that don't
              # match it's own set, then we're going to declare a new rule - this allows
              # an author to define {table mobile="collapse" mobile-style="..."} to be
              # completely different from {td mobile="collapse" mobile-style="..."} which
              # can be useful when defining behaviors and keeping HTML readable.
              rule = nil

            end

          end

        end

        if rule.nil?
          rule = Rule.new(tag, klass, declarations)

          # Add the rule to the list of those that will be rendered into the
          # completed email.
          ctx.responsive_styles << rule

        elsif !rule.include?(tag)
          rule << tag

        end

        # Mark the rule as active in case it was one of the pre-defined rules
        # that can be activated on first use.
        rule.activate!

        # Make sure classes is an array and prepopulate it with any existing
        # class that was provided
        classes = []
        classes << att[:class] unless att[:class].blank?
        classes << rule.klass

        att[:class] = classes

        true
      end

      def self.presets ctx

        styles = []

        # HIDE, which can be used on any responsive element, makes it disappear
        # on mobile devices.
        styles << Rule.new(UNIVERSAL, HIDE, 'display: none !important;', false)

        # Brian Graves' Column Drop Pattern: Table goes to 100% width by way of
        # the FILL rule and its cells stack vertically.
        # http://briangraves.github.io/ResponsiveEmailPatterns/patterns/layouts/column-drop.html
        styles << Rule.new('td', DROP, 'display: block; width: 100% !important; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box;', false)

        # FILL causes specific types of elements to expand to 100% of the available
        # width of the mobile device.
        styles << Rule.new('img', FILL, 'width: 100% !important; height: auto !important;', false)
        styles << Rule.new([ 'table', 'td' ], FILL, 'width: 100% !important; background-size: 100% auto !important;', false)

        # BUTTON causes ordinary links to transform into buttons based
        # on the styles configured by the developer.
        cfg = Button::Config.new(ctx)

        sty = {
            :color => "#{cfg.color} !important",
            BACKGROUND_COLOR => cfg.bgcolor,
            TEXT_SHADOW => "0 -1px 0 #{cfg.text_shadow}"
        }

        sty[:border] = cfg.border unless cfg.border.blank?
        sty[BORDER_RADIUS] = Renderer.px(cfg.border_radius) if cfg.border_radius > 0
        sty[FONT_WEIGHT] = cfg.font_weight unless cfg.font_weight.blank?
        sty[:height] = Renderer.px(cfg.height) if cfg.height > 0
        sty[LINE_HEIGHT] = Renderer.px(cfg.line_height) if cfg.line_height > 0
        sty[MARGIN_TOP] = Renderer.px(cfg.margin_top) if cfg.margin_top > 0
        sty[:padding] = Renderer.px(cfg.padding) if cfg.padding > 0
        sty[TEXT_ALIGN] = 'center'

        styles << Rule.new('a', BUTTON, sty, false)

        styles
      end

      private

      # Attribute used to declare custom mobile styles for an element.
      MOBILE_STYLE = :'mobile-style'

      # Universal CSS selector.
      UNIVERSAL = '*'

    end
  end
end
