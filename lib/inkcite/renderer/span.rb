module Inkcite
  module Renderer
    class Span < Responsive

      def render tag, opt, ctx

        return '</span>' if tag == '/span'

        span = Element.new('span')

        mix_font span, opt, ctx

        mix_responsive span, opt, ctx

        span.to_s
      end

    end
  end
end

