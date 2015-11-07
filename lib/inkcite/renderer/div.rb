module Inkcite
  module Renderer
    class Div < Responsive

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        width = opt[:width]
        div.style[:width] = px(width) unless width.blank?

        height = opt[:height].to_i
        div.style[:height] = px(height) if height > 0

        mix_background div, opt
        mix_font div, opt, ctx

        # Text alignment - left, right, center.
        align = opt[:align]
        div.style[TEXT_ALIGN] = align unless none?(align)

        valign = opt[:valign]
        div.style[VERTICAL_ALIGN] = valign unless valign.blank?

        display = opt[:display]
        div.style[:display] = display unless display.blank?

        mix_responsive div, opt, ctx

        div.to_s
      end

    end
  end
end
