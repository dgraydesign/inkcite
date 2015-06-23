module Inkcite
  module Renderer
    class Preheader < Base

      def render tag, opt, ctx

        if tag == '/preheader'
          '</span>'

        else

          # Preheader text styling courtesy "Don’t forget about preheader text" section of
          # Lee Munroe's blog entry: http://www.leemunroe.com/building-html-email/
          '<span style="color: transparent; display: none !important; height: 0; max-height: 0; max-width: 0; opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;">'

        end

      end

    end
  end
end
