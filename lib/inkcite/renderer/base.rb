module Inkcite
  module Renderer
    class Base

      # Constants for style and property names with dashes in them.
      BACKGROUND_COLOR    = :'background-color'
      BACKGROUND_IMAGE    = :'background-image'
      BACKGROUND_REPEAT   = :'background-repeat'
      BACKGROUND_POSITION = :'background-position'
      BACKGROUND_SIZE     = :'background-size'
      BORDER_BOTTOM       = :'border-bottom'
      BORDER_COLLAPSE     = :'border-collapse'
      BORDER_RADIUS       = :'border-radius'
      BORDER_SPACING      = :'border-spacing'
      BOX_SHADOW          = :'box-shadow'
      FONT_FAMILY         = :'font-family'
      FONT_SIZE           = :'font-size'
      FONT_WEIGHT         = :'font-weight'
      LETTER_SPACING      = :'letter-spacing'
      LINE_HEIGHT         = :'line-height'
      LINK_COLOR          = :'#link'
      MARGIN_TOP          = :'margin-top'
      PADDING_X           = :'padding-x'
      PADDING_Y           = :'padding-y'
      TEXT_ALIGN          = :'text-align'
      TEXT_DECORATION     = :'text-decoration'
      TEXT_SHADOW         = :'text-shadow'
      TEXT_SHADOW_BLUR    = :'shadow-blur'
      TEXT_SHADOW_OFFSET  = :'shadow-offset'
      VERTICAL_ALIGN      = :'vertical-align'

      # CSS Directions
      DIRECTIONS = [ :top, :right, :bottom, :left ]

      # Attribute and CSS dimensions
      DIMENSIONS = [ :width, :height ]

      # Common value declarations
      POUND_SIGN = '#'
      NONE       = 'none'

      # Zero-width space character
      ZERO_WIDTH_SPACE = '&#8203;'

      def render tag, opt, ctx
        raise "Not implemented: #{tag} #{opts}"
      end

      protected

      # Convenience proxy
      def detect *opts
        Util.detect(*opts)
      end

      def detect_font att, font, opt, parent, ctx
        val = detect(opt[att], ctx["#{font}-#{att}"], parent ? parent[att] : nil)

        # Sometimes font values reference other defined values so we need
        # to run them through the renderer to resolve them.
        val = Inkcite::Renderer.render(val, ctx)

        # Convience
        val = nil if none?(val)

        val
      end

      # Convenience pass-thru to Renderer's static helper method.
      def hex color
        Renderer.hex(color)
      end

      def none? val
        val.blank? || val == NONE
      end

      # Sets the element's in-line bgcolor style if it has been defined
      # in the provided options.
      def mix_background element, opt

        # Background color of the image, if populated.
        bgcolor = detect(opt[:bgcolor], opt[BACKGROUND_COLOR])
        element.style[BACKGROUND_COLOR] = hex(bgcolor) unless none?(bgcolor)

      end

      def mix_font element, opt, ctx, parent=nil

        # Always ensure we have a parent to inherit from.
        parent ||= {}

        # Check for a font in either the element's specified options or inherit a setting from
        # from the parent if provided.
        font = detect(opt[:font], parent[:font])

        # Fonts can be disabled on individual cells if the parent table
        # has set one for the entire table.
        font = nil if none?(font)

        font_family = detect_font(FONT_FAMILY, font, opt, parent, ctx)
        element.style[FONT_FAMILY] = font_family unless font_family.blank?

        font_size = detect_font(FONT_SIZE, font, opt, parent, ctx)
        element.style[FONT_SIZE] = px(font_size) unless font_size.blank?

        color = detect_font(:color, font, opt, parent, ctx)
        element.style[:color] = hex(color) unless color.blank?

        line_height = detect_font(LINE_HEIGHT, font, opt, parent, ctx)
        element.style[LINE_HEIGHT] = px(line_height) unless line_height.blank?

        font_weight = detect_font(FONT_WEIGHT, font, opt, parent, ctx)
        element.style[FONT_WEIGHT] = font_weight unless font_weight.blank?

        letter_spacing = detect_font(LETTER_SPACING, font, opt, parent, ctx)
        element.style[LETTER_SPACING] = px(letter_spacing) unless none?(letter_spacing)

        # With font support comes text shadow support.
        mix_text_shadow element, opt, ctx

        font
      end

      def mix_text_shadow element, opt, ctx

        shadow = detect(opt[:shadow], opt[TEXT_SHADOW])
        return if shadow.blank?

        # Allow shadows to be disabled because sometimes a child element (like an
        # image within a cell or an entire cell within a table) wants to disable
        # the shadowing forced by a parent.
        if none?(shadow)
          element.style[TEXT_SHADOW] = shadow

        else

          shadow_offset = detect(opt[TEXT_SHADOW_OFFSET], ctx[TEXT_SHADOW_OFFSET], 1)
          shadow_blur = detect(opt[TEXT_SHADOW_BLUR], ctx[TEXT_SHADOW_BLUR], 0)

          element.style[TEXT_SHADOW] = "0 #{px(shadow_offset)} #{px(shadow_blur)} #{hex(shadow)}"

        end

      end

      def px val
        Renderer.px(val)
      end

      def quote val
        Renderer.quote(val)
      end

      def render_tag tag, attributes=nil, styles=nil

        # Convert the style hash into CSS style attribute.
        unless styles.blank?
          attributes ||= {}
          attributes[:style] = quote(Renderer.render_styles(styles))
        end

        # Check to see if this is a self-closing tag.
        self_close = attributes && attributes.delete(:self_close) == true

        html = "<#{tag}"

        unless attributes.blank?

          # Make sure multiple classes are handled properly.
          classes = attributes[:class]
          attributes[:class] = quote([*classes].join(' ')) unless classes.blank?

          html << SPACE + Renderer.join_hash(attributes)

        end

        html << '/' if self_close
        html << '>'

        html
      end

    end
  end
end
