module Inkcite
  module Renderer
    class Div < Responsive

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        height = opt[:height].to_i
        div.style[:height] = px(height) if height > 0

        # Text alignment - left, right, center.
        align = opt[:align]
        div.style[TEXT_ALIGN] = align unless none?(align)

        mix_font div, opt, ctx

        mix_background div, opt

        mix_responsive div, opt, ctx

        div.to_s
      end

    end
  end
end
