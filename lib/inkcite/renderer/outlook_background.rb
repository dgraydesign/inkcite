module Inkcite
  module Renderer

    # Outlook background image support courtesy of @stigm via Campaign Monitor's
    # Bulletproof Background Images: https://backgrounds.cm/
    #
    # {outlook-bg src=YJOX1PC.png bgcolor=#7bceeb height=92 width=120}
    #   ...
    # {/outlook-bg}
    #
    class OutlookBackground < ImageBase

      def render tag, opt, ctx

        # Do nothing if vml is disabled globally.  Disable by setting
        # 'vml: false' in config.yml
        return nil unless ctx.vml_enabled?

        html = '{if test="gte mso 9"}'

        if tag == '/outlook-bg'
          html << '</div>'
          html << '</v:textbox>'
          html << '</v:rect>'

        else

          # Get the fully-qualified URL to the image or placeholder image if it's
          # missing from the images directory.
          src = image_url(opt[:src], opt, ctx, false)

          rect = Element.new('v:rect', {
                  :'xmlns:v' => quote('urn:schemas-microsoft-com:vml'),
                  :fill => quote(true),
                  :stroke => quote(false)
              })

          width = opt[:width]
          height = opt[:height].to_i

          # When width is omitted, set to 100% or marked as 'fill' then
          # make the image fill the available space.  It will tile.
          if width.nil? || width == 'fill' || width == '100%' || width.to_i <= 0

            # The number you pass to 'mso-width-percent' is ten times the percentage you'd like.
            # https://www.emailonacid.com/blog/article/email-development/emailology_vector_markup_language_and_backgrounds
            rect.style[:'mso-width-percent'] = 1000

          else
            rect.style[:width] = px(width)

          end

          # True if the height of the background image will fit to content within the
          # background element (specified by omitting the 'height' attribute).
          fit_to_shape = height <= 0
          rect.style[:height] = px(height) unless fit_to_shape

          fill = Element.new('v:fill', {
                  :type => '"tile"',
                  :src => src,
                  :self_close => true
              })

          # Check for a background color.
          bgcolor = opt[:bgcolor]
          fill[:color] = quote(hex(bgcolor)) unless bgcolor.blank?

          textbox = Element.new('v:textbox', :inset => '"0,0,0,0"')
          textbox.style[:'mso-fit-shape-to-text'] = 'true' if fit_to_shape

          html << rect.to_s
          html << fill.to_s
          html << textbox.to_s

          div = Element.new('div')

          # Font family and other attributes get reset within the v:textbox so allow
          # the font series of attributes to be applied.
          mix_font div, opt, ctx

          html << div.to_s

          # Flag the context as having had VML used within it.
          ctx.vml_used!

        end

        html << '{/if}'

        html
      end

    end
  end
end
