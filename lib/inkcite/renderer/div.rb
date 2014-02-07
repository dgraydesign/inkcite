module Inkcite
  module Renderer
    class Div < Responsive

      def render tag, opt, ctx

        return '</div>' if tag == '/div'

        att = { }
        sty = { }

        mix_responsive tag, opt, att, sty, ctx

        render_tag tag, att, sty
      end

    end
  end
end
