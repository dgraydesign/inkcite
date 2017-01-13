module Inkcite
  module Renderer
    class Div < ContainerBase

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        mix_width div, opt, ctx

        height = opt[:height].to_i
        div.style[:height] = px(height) if height > 0

        mix_all div, opt, ctx
      end

    end
  end
end
