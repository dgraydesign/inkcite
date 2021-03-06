module Inkcite
  module Renderer
    class Responsive < Base

      BUTTON = 'button'
      DROP = 'drop'
      FILL = 'fill'
      FLUID = 'fluid'
      FLUID_DROP = 'fluid-drop'
      FLUID_STACK = 'fluid-stack'
      HIDE = 'hide'
      IMAGE = 'img'
      SHOW = 'show'
      SHOW_INLINE = 'show-inline'
      SWITCH = 'switch'
      SWITCH_UP = 'switch-up'
      TOGGLE = 'toggle'

      # For elements that take on different background properties
      # when they go responsive
      MOBILE_BGCOLOR = :'mobile-bgcolor'
      MOBILE_BACKGROUND = :'mobile-background'
      MOBILE_BACKGROUND_COLOR = :'mobile-background-color'
      MOBILE_BACKGROUND_IMAGE = :'mobile-background-image'
      MOBILE_BACKGROUND_REPEAT = :'mobile-background-repeat'
      MOBILE_BACKGROUND_POSITION = :'mobile-background-position'
      MOBILE_BACKGROUND_SIZE = :'mobile-background-size'
      MOBILE_SRC = :'mobile-src'

      # Other mobile-specific properties
      MOBILE_HEIGHT = :'mobile-height'
      MOBILE_MAX_WIDTH = :'mobile-max-width'
      MOBILE_PADDING = :'mobile-padding'
      MOBILE_WIDTH = :'mobile-width'

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

        def att_selector_string
          ".#{@klass}"
        end

        def block?
          declaration_string.downcase.include?('block')
        end

        def declaration_string
          if @declarations.is_a?(Hash)
            Renderer.render_styles(@declarations)
          elsif @declarations.is_a?(Array)
            @declarations.join(' ')
          else
            @declarations.to_s
          end
        end

        def include? tag
          universal? || @tags.include?(tag)
        end

        def to_css

          rule = ""

          att_selector = att_selector_string

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
          rule << declaration_string
          rule << " }"

          rule
        end

        def universal?
          @tags.include?(UNIVERSAL)
        end

      end

      class TargetRule < Rule

        def initialize tag, klass
          super tag, klass, 'display: block !important;'
        end

        def att_selector_string
          "[id=#{@klass}]:target"
        end

      end

      def self.presets ctx

        styles = []

        # HIDE, which can be used on any responsive element, makes it disappear
        # on mobile devices.
        styles << Rule.new(UNIVERSAL, HIDE, 'display: none !important;', false)

        # SHOW, which means the element is hidden on desktop but shown on mobile.
        styles << Rule.new('div', SHOW, 'display: block !important; max-height: none !important;', false)
        styles << Rule.new('div', SHOW_INLINE, 'display: inline !important; max-height: none !important;', false)

        # Brian Graves' Column Drop Pattern: Table goes to 100% width by way of
        # the FILL rule and its cells stack vertically.
        # http://briangraves.github.io/ResponsiveEmailPatterns/patterns/layouts/column-drop.html
        styles << Rule.new('td', DROP, 'display: block; width: 100% !important; background-size: 100% auto !important; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box;', false)

        # Brian Graves' Column Switch Pattern: Allows columns in a table to
        # be reordered based on up and down states.
        # http://www.degdigital.com/blog/content-choreography-in-responsive-email/
        styles << Rule.new('td', SWITCH, 'display: table-footer-group; width: 100% !important; background-size: 100% auto !important;', false)
        styles << Rule.new('td', SWITCH_UP, 'display: table-header-group; width: 100% !important; background-size: 100% auto !important;', false)

        # FILL causes specific types of elements to expand to 100% of the available
        # width of the mobile device.
        styles << Rule.new('img', FILL, 'width: 100% !important; height: auto !important;', false)
        styles << Rule.new(['table', 'td'], FILL, 'width: 100% !important; background-size: 100% auto !important;', false)

        # For mobile-image tags.
        styles << Rule.new('span', IMAGE, 'display: block; background-position: center; background-size: cover;', false)

        # BUTTON causes ordinary links to transform into buttons based
        # on the styles configured by the developer.
        cfg = Button::Config.new(ctx)

        button_styles = {
            :color => "#{cfg.color} !important",
            :display => 'block'
        }

        button_styles[BACKGROUND_COLOR] = cfg.bgcolor unless cfg.bgcolor.blank?
        button_styles[:border] = cfg.border unless cfg.border.blank?
        button_styles[BORDER_BOTTOM] = cfg.border_bottom if cfg.bevel > 0
        button_styles[BORDER_RADIUS] = Renderer.px(cfg.border_radius) unless cfg.border_radius.blank?
        button_styles[FONT_WEIGHT] = cfg.font_weight unless cfg.font_weight.blank?
        button_styles[:height] = Renderer.px(cfg.height) if cfg.height > 0
        button_styles[MARGIN_TOP] = Renderer.px(cfg.margin_top) if cfg.margin_top > 0
        button_styles[:padding] = Renderer.px(cfg.padding) unless cfg.padding.blank?
        button_styles[TEXT_ALIGN] = 'center'
        button_styles[TEXT_SHADOW] = "0 -1px 0 #{cfg.text_shadow}" unless cfg.text_shadow.blank?

        styles << Rule.new('a', BUTTON, button_styles, false)

        styles
      end

      protected

      # Returns true if the mobile klass provided matches any of the
      # Fluid-Hybrid classes.
      def is_fluid? mobile
        mobile == FLUID || is_fluid_drop?(mobile)
      end

      # Returns true if the mobile klass provided matches any of the
      # Fluid-Hybrid classes that result in a table's columns stacking
      # vertically.
      def is_fluid_drop? mobile
        mobile == FLUID_DROP || mobile == FLUID_STACK
      end

      def mix_border element, opt, ctx
        super
        mix_directional element, element.mobile_style, opt, ctx, MOBILE_BORDER, :border
      end

      def mix_dimensions element, opt, ctx

        max_width = opt[MOBILE_MAX_WIDTH]
        element.mobile_style[MAX_WIDTH] = px(max_width) unless max_width.blank?

      end

      def mix_font element, opt, ctx, parent=nil

        # Let the super class do its thing and grab the name of the font
        # style that was applied, if any.
        font = super

        # Will hold the mobile font overrides for this element, if any.
        font_family = detect_font(MOBILE_FONT_FAMILY, font, opt, parent, ctx)
        element.mobile_style[FONT_FAMILY] = font_family unless font_family.blank?

        font_size = detect_font(MOBILE_FONT_SIZE, font, opt, parent, ctx)
        element.mobile_style[FONT_SIZE] = px(font_size) unless font_size.blank?

        color = detect_font(MOBILE_FONT_COLOR, font, opt, parent, ctx)
        element.mobile_style[:color] = hex(color) unless color.blank?

        font_weight = detect_font(MOBILE_FONT_WEIGHT, font, opt, parent, ctx)
        element.mobile_style[FONT_WEIGHT] = font_weight unless font_weight.blank?

        letter_spacing = detect_font(MOBILE_LETTER_SPACING, font, opt, parent, ctx)
        element.mobile_style[LETTER_SPACING] = px(letter_spacing) unless none?(letter_spacing)

        line_height = detect_font(MOBILE_LINE_HEIGHT, font, opt, parent, ctx)
        element.mobile_style[LINE_HEIGHT] = px(line_height) unless line_height.blank?

        font
      end

      def mix_margins element, opt, ctx, outlookCompatible=true
        super
        mix_directional element, element.mobile_style, opt, ctx, MOBILE_MARGIN, :margin, true
      end

      def mix_mobile_padding element, opt, ctx
        mix_directional element, element.mobile_style, opt, ctx, MOBILE_PADDING, :padding, true
      end

      # A separate method for mixing in text alignment because the table cell
      # helper handles alignment different from normal container elements.
      def mix_mobile_text_align element, opt, ctx

        # Support for mobile-text-align
        align = opt[MOBILE_TEXT_ALIGN]
        element.mobile_style[TEXT_ALIGN] = align unless none?(align)

      end

      def mix_responsive element, opt, ctx, klass=nil

        mobile_style = opt[MOBILE_STYLE]
        ctx.error 'mobile-style is no longer supported', { :element => element.to_s, MOBILE_STYLE => mobile_style } unless mobile_style.blank?

        mobile_display = opt[MOBILE_DISPLAY]
        element.mobile_style[:display] = mobile_display unless none?(mobile_display)

        # Apply the "mobile" attribute or use the override if one was provided.
        mix_responsive_klass element, opt, ctx, klass || opt[:mobile]

        # Apply the "mobile-style" attribute if one was provided.
        mix_responsive_style element, opt, ctx

      end

      def mix_responsive_klass element, opt, ctx, klass

        # Nothing to do if there is no class specified.s
        return nil if klass.blank?

        # The Fluid-Hybrid klass is also ignored because it doesn't involve
        # media queries - aborting early to avoid the "missing mobile class"
        # warning normally generated.
        return nil if is_fluid?(klass)

        mq = ctx.media_query

        # The element's tag - e.g. table, td, etc.
        tag = element.tag

        # Special handling for TOGGLE-able elements which are made
        # visible by another element being clicked.
        if klass == TOGGLE

          id = opt[:id]
          if id.blank?
            ctx.errors 'Mobile elements with toggle behavior require an ID attribute', { :tag => tag } if id.blank?

          else

            # Make sure the element's ID field is populated
            element[:id] = id

            # Add a rule which makes this element visible when the target
            # field matches the identity.
            mq << TargetRule.new(tag, id)

            # Toggle-able elements are HIDE on mobile by default.
            klass = HIDE

          end
        end

        # Check to see if there is already a rule that specifically matches this klass
        # and tag combination - e.g. td.hide
        rule = mq.find_by_tag_and_klass(tag, klass)
        if rule.nil?

          # If no rule was found then find the first that matches the klass.
          rule = mq.find_by_klass(klass)

          # If no rule was found and the declaration is blank then we have
          # an unknown mobile behavior.
          if rule.nil?
            ctx.error 'Undefined mobile behavior - are you missing a mobile-style declaration?', { :tag => tag, :mobile => klass }
            return nil
          end

          rule << tag if !rule.include?(tag)

        end

        # Add the responsive rule to the element
        element.add_rule rule

      end

      def mix_responsive_style element, opt, ctx

        # Warn that mobile-style is no longer supported.  Developers should
        # use the stronger, faster, better-er mobile-* attributes
        __unsupported_style = element[MOBILE_STYLE]
        ctx.errors('The mobile-style attribute is no longer supported', { :element => element.to_s, :mobile_style => __unsupported_style }) unless __unsupported_style.blank?

        _mobile_style = element.mobile_style
        return if _mobile_style.blank?

        # Will hold a preprocessed list of direction-free, lowercased properties
        # (ahem, Outlook Margin) so we can easily determine if a mobile style
        # needs !important to override its desktop style value.
        desktop_style_keys = Set.new
        desktop_style = {}
        element.style.each_pair do |key, css|

          key = key.to_s.downcase
          desktop_style[key.to_sym] = css

          base_key = get_directionless_key(key)
          desktop_style_keys.add(base_key)

        end

        # This will hold the decorated list of CSS properties.  If the element
        # has any existing styles that are being overridden in the mobile styles
        # we need to append the !important flag.
        decorated_style = {}

        # Iterate through the defined mobile styles, determine which need to
        # have !important and assemble a new hash to be rendered as CSS.
        _mobile_style.each_pair do |key, css|

          # No need to put attributes in the mobile style if they match
          # the existing desktop style of the element.
          next if css == desktop_style[key]

          # Append !important to the CSS if it overrides a value in the
          # element's in-lined styles.  Need to test bo
          base_key = get_directionless_key(key)
          css = "#{css} !important" if desktop_style_keys.include?(base_key)

          decorated_style[key] = css
        end

        # Render the array of styles to a CSS declaration string
        declarations = Renderer.render_styles decorated_style
        return if declarations.blank?

        mq = ctx.media_query

        tag = element.tag

        # If no klass was specified, check to see if any previously defined rule matches
        # the style declarations.  If so, we'll reuse that rule and apply the klass
        # to this object to avoid unnecessary duplication in the HTML.
        rule = mq.find_by_declaration(declarations)
        if rule.nil?

          # Generate a unique class name for this style if it has not already been declared.
          # These are of the form m001, etc.  Readability is not important because it's
          # dynamically generated and referenced.
          klass = unique_klass(ctx)

          rule = Rule.new(tag, klass, declarations)

          # Add the rule to the list of those that will be rendered into the
          # completed email.
          mq << rule

        elsif !rule.include?(tag)

          # Make sure this tag is included in the list of those that
          # the CSS will match against.
          rule << tag

        end

        # Add the responsive rule to the element which automatically adds its
        # class to the element's list.
        element.add_rule rule

      end

      def mix_text_align element, opt, ctx
        super
        mix_mobile_text_align element, opt, ctx
      end

      def unique_klass ctx
        'm%1d' % ctx.unique_id(:m)
      end

      private

      # Attribute used to declare custom mobile styles for an element.
      MOBILE_BORDER = :'mobile-border'
      MOBILE_DISPLAY = :'mobile-display'
      MOBILE_MARGIN = :'mobile-margin'
      MOBILE_STYLE = :'mobile-style'
      MOBILE_TEXT_ALIGN = :'mobile-text-align'

      # Universal CSS selector.
      UNIVERSAL = '*'

      # For font overrides on mobile devices.  These values are read from
      # the object's attributes and installed into the element's mobile_styles.
      MOBILE_FONT_COLOR = :'mobile-color'
      MOBILE_FONT_FAMILY = :'mobile-font-family'
      MOBILE_FONT_SIZE = :'mobile-font-size'
      MOBILE_FONT_WEIGHT = :'mobile-font-weight'
      MOBILE_LETTER_SPACING = :'mobile-letter-spacing'
      MOBILE_LINE_HEIGHT = :'mobile-line-height'

      # Accepts a key, such as border or border-left, and returns the
      # key sans direction suffix - so border and border respectively.
      # The opposite of add_directional_suffix().
      def get_directionless_key key
        key = key.to_s

        # Iterate through the possible directions and if the key ends
        # with the separator and direction (e.g. -left) trim that off
        # and return it.
        DIRECTIONS.each do |dir|
          dir = "-#{dir}"
          return key[0, dir.length] if key.end_with?(dir)
        end

        key
      end

    end
  end
end
