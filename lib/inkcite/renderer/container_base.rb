module Inkcite
  module Renderer
    class ContainerBase < Responsive

      protected

      def mix_all element, opt, ctx

        mix_animation element, opt, ctx
        mix_background element, opt, ctx
        mix_border element, opt, ctx
        mix_border_radius element, opt, ctx
        mix_font element, opt, ctx
        mix_margins element, opt, ctx
        mix_text_align element, opt, ctx

        # Supports both integers and mixed padding (e.g. 10px 20px)
        padding = opt[:padding]
        element.style[:padding] = px(padding) unless none?(padding)

        # Vertical alignment - top, middle, bottom.
        valign = opt[:valign]
        element.style[VERTICAL_ALIGN] = valign unless none?(valign)

        display = opt[:display]
        element.style[:display] = display unless display.blank?

        # If boolean 'nowrap' attribute is present, apply the 'white-space: nowrap'
        # style to the element.
        element.style[WHITE_SPACE] = :nowrap if opt[:nowrap]

        # Support for mobile-padding and mobile-padding-(direction)
        mix_mobile_padding element, opt, ctx

        mix_responsive element, opt, ctx

        element.to_s
      end

      def mix_width element, opt, ctx

        width = opt[:width]
        element.style[:width] = px(width) unless width.blank?

        mobile_width = opt[MOBILE_WIDTH]
        element.mobile_style[:width] = px(mobile_width) unless mobile_width.blank?

      end

    end
  end
end
