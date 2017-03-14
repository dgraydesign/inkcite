module Inkcite
  module Renderer
    class Div < ContainerBase

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        mix_width div, opt, ctx
        mix_height div, opt, ctx

        mix_all div, opt, ctx
      end

    end
  end
end
