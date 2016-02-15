module Inkcite
  module Renderer
    class ContainerBase < Responsive

      protected

      def mix_all element, opt, ctx

        mix_background element, opt, ctx
        mix_border element, opt, ctx
        mix_border_radius element, opt, ctx
        mix_font element, opt, ctx
        mix_text_align element, opt, ctx

        # Supports both integers and mixed padding (e.g. 10px 20px)
        padding = opt[:padding]
        element.style[:padding] = px(padding) unless none?(padding)

        # Vertical alignment - top, middle, bottom.
        valign = opt[:valign]
        element.style[VERTICAL_ALIGN] = valign unless none?(valign)

        display = opt[:display]
        element.style[:display] = display unless display.blank?

        mix_responsive element, opt, ctx

        element.to_s
      end


      # Text alignment - left, right, center.
      def mix_text_align element, opt, ctx

        align = opt[:align]
        element.style[TEXT_ALIGN] = align unless none?(align)

      end

    end
  end
end
