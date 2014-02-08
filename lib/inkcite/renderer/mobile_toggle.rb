# Brian Graves' Toggle Responsive Pattern
# http://briangraves.github.io/ResponsiveEmailPatterns/patterns/navigation/toggle.html
module Inkcite
  module Renderer

    class MobileToggleOn < Responsive

      def render tag, opt, ctx

        return '{/a}' if tag == '/mobile-toggle-on'

        id = opt[:id]
        if id.blank?
          ctx.error('The mobile-toggle-on requires an id')

        else
          "{a href=\"##{id}\" mobile=\"show\"}"

        end

      end

    end

  end
end

