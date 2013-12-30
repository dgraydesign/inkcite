module Inkcite
  module Renderer
    class Base

      # Constants for style and property names with dashes in them.
      BACKGROUND_COLOR    = :'background-color'
      BACKGROUND_IMAGE    = :'background-image'
      BACKGROUND_REPEAT   = :'background-repeat'
      BACKGROUND_POSITION = :'background-position'
      BACKGROUND_SIZE     = :'background-size'
      BORDER_RADIUS       = :'border-radius'
      BORDER_SPACING      = :'border-spacing'
      BOX_SHADOW          = :'box-shadow'
      FONT_FAMILY         = :'font-family'
      FONT_SIZE           = :'font-size'
      FONT_WEIGHT         = :'font-weight'
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

      def render tag, opt, ctx
        raise "Not implemented: #{tag} #{opts}"
      end

      protected

      # Convenience pass-thru to Renderer's static helper method.
      def hex color
        Renderer.hex(color)
      end

      def mix_text_shadow opt, sty, ctx

        shadow = opt[:shadow] || opt[TEXT_SHADOW]
        return if shadow.blank?

        # Allow shadows to be disabled because sometimes a child element (like an
        # image within a cell or an entire cell within a table) wants to disable
        # the shadowing forced by a parent.
        if shadow == NONE
          sty[TEXT_SHADOW] = shadow

        else
          shadow_offset = opt[TEXT_SHADOW_OFFSET] || 1
          shadow_blur = opt[TEXT_SHADOW_BLUR] || 0
          sty[TEXT_SHADOW] = "0 #{px(shadow_offset)} #{px(shadow_blur)} #{hex(shadow)}"

        end

      end

      # Returns the provided integer value with a "px" extension unless
      # the value is zero and the px extension can be excluded.
      def px val
        val = val.to_i
        val = "#{val}px" unless val == 0
        val
      end

      def quote val
        "\"#{val}\""
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
        html << SPACE + Renderer.join_hash(attributes) unless attributes.blank?
        html << '/' if self_close
        html << '>'

        html
      end

    end
  end
end
