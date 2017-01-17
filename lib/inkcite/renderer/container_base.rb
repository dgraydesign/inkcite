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

        # Supports custom padding on mobile - e.g. mobile-padding="15px 5px"
        mobile_padding = opt[MOBILE_PADDING]
        element.mobile_style[:padding] = px(mobile_padding) unless none?(mobile_padding)

        # Vertical alignment - top, middle, bottom.
        valign = opt[:valign]
        element.style[VERTICAL_ALIGN] = valign unless none?(valign)

        display = opt[:display]
        element.style[:display] = display unless display.blank?

        # If boolean 'nowrap' attribute is present, apply the 'white-space: nowrap'
        # style to the element.
        element.style[WHITE_SPACE] = :nowrap if opt[:nowrap]

        mix_responsive element, opt, ctx

        element.to_s
      end

      def mix_width element, opt, ctx

        width = opt[:width]
        element.style[:width] = px(width) unless width.blank?

      end

    end
  end
end
