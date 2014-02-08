# Brian Graves' Toggle Responsive Pattern
# http://briangraves.github.io/ResponsiveEmailPatterns/patterns/navigation/toggle.html
module Inkcite
  module Renderer

    class MobileToggleOn < Responsive

      def render tag, opt, ctx

        return '</a>' if tag == '/mobile-toggle-on'

        # Mobile toggles use anchors to link to specific
        # targets (e.g. #menu).
        tag = 'a'

        id = opt[:id]
        if id.blank?
          ctx.error('The mobile-toggle-on requires an id')

        else

          att = {
              :href => "##{id}"
          }

          sty = { }

          float = opt[:float] || opt[:align]
          sty[:float] = float unless float.blank?

          # Force the link to only display during mobile.
          mix_responsive tag, opt, att, sty, ctx, SHOW

          render_tag tag, att, sty
        end

      end

    end

  end
end

