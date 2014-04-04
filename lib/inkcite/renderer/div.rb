module Inkcite
  module Renderer
    class Div < Responsive

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        mix_font div, opt, ctx
        mix_text_shadow div, opt, ctx

        mix_background div, opt

        mix_responsive div, opt, ctx

        div.to_s
      end

    end
  end
end
