module Inkcite
  module Renderer
    class OutlookBackground < Base

      def render tag, opt, ctx

        # Do nothing if vml is disabled globally.
        return nil unless ctx.vml_enabled?

        html = '<!--[if gte mso 9]>'

        if tag == '/outlook-bg'
          html << '</div>'
          html << '</v:textbox>'
          html << '</v:rect>'

        else

          src = opt[:src]
          raise 'Outlook background missing required src attribute' if src.blank?

          width = opt[:width].to_i
          height = opt[:height].to_i
          raise "Outlook background requires dimensions: #{width}x#{height} " if width <= 0 || height <= 0

          html << render_tag('v:rect',
              { :'xmlns:v' => quote('urn:schemas-microsoft-com:vml'), :fill => quote(true), :stroke => quote(false) },
              { :width => px(width), :height => px(height) }
          )

          html << render_tag('v:fill', { :type => 'tile', :src => quote(ctx.image_url(src)), :color => hex(opt[:bgcolor]), :self_close => true })

          html << render_tag('v:textbox', { :inset => '0,0,0,0' })
          html << '<div>'

          # Flag the context as having had VML used within it.
          ctx.vml_used!

        end

        html << '<![endif]-->'

        html
      end

    end
  end
end
