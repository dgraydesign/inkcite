module Inkcite
  module Renderer
    class Div < ContainerBase

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        div = Element.new('div')

        width = opt[:width]
        div.style[:width] = px(width) unless width.blank?

        height = opt[:height].to_i
        div.style[:height] = px(height) if height > 0

        mix_all div, opt, ctx
      end

    end
  end
end
