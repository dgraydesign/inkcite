module Inkcite
  module Renderer
    class Span < Responsive

      def render tag, opt, ctx

        return '</span>' if tag == '/span'

        span = Element.new('span')

        padding = opt[:padding].to_i
        span.style[:padding] = px(padding) if padding > 0

        mix_font span, opt, ctx

        mix_background span, opt

        mix_responsive span, opt, ctx

        span.to_s
      end

    end
  end
end

