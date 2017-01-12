module Inkcite
  module Renderer

    # Bulletproof background image support courtesy of @stigm via Campaign Monitor
    # https://backgrounds.cm/
    #
    # {background src=YJOX1PC.png bgcolor=#7bceeb height=92 width=120}
    #   ...
    # {/background}
    #
    class Background < ImageBase

      def render tag, opt, ctx

        html = ''

        if tag == '/background'

          html << '</div>'

          # If VML is enabled, then close the textbox and rect that were created
          # by the opening tags.
          if ctx.vml_enabled?
            html << '{outlook-only}'
            html << '</v:textbox>'
            html << '</v:rect>'
            html << '{/outlook-only}'
          end

          html << '{/td}'
          html << '{/table}'

        else

          # Primary background image
          src = opt[:src]

          # Dimensions
          width = opt[:width]
          height = opt[:height].to_i

          # True if the background image's width should fill the available
          # horizontal space.  Specified by either leaving the width blank or
          # specifying 'fill' or '100%'
          fill_width = width.nil? || width == 'fill' || width == '100%' || width.to_i <= 0

          table = Element.new('table')
          table[:height] = height if height > 0
          table[:width] = (fill_width ? '100%' : width)
          table[:background] = quote(src) unless none?(src)

          # Iterate through the list of the parameters that are copied straight into
          # the internal {table} Helper.  This is a sanitized list of supported
          # parameters to prevent the user from setting things inadvertently that
          # might interfere with the display of the background (e.g. padding)
          TABLE_PASSTHRU_OPS.each do |key|
            val = opt[key]
            table[key] = quote(val) unless none?(val)
          end

          # Determine if a fallback background color has been defined.
          bgcolor = detect_bgcolor(opt)
          table[:bgcolor] = quote(bgcolor) unless none?(bgcolor)

          # Check for a background gradient
          bggradient = detect_bggradient(opt)
          table[:bggradient] = quote(bggradient) unless none?(bggradient)

          td = Element.new('td')

          valign = opt[:valign]
          td[:valign] = valign unless valign.blank?

          html << table.to_helper
          html << td.to_helper

          # VML is only added if it is enabled for the project.
          if ctx.vml_enabled?

            # Get the fully-qualified URL to the image or placeholder image if it's
            # missing from the images directory.  This comes back with quotes around it.
            outlook_src = image_url(opt[OUTLOOK_SRC] || src, opt, ctx, false)

            # True if the height of the background image will fit to content within the
            # background element (specified by omitting the 'height' attribute).
            fit_to_shape = height <= 0

            rect = Element.new('v:rect', { :'xmlns:v' => quote('urn:schemas-microsoft-com:vml'), :fill => quote('t'), :stroke => quote('f') })

            if fill_width

              # The number you pass to 'mso-width-percent' is ten times the percentage you'd like.
              # https://www.emailonacid.com/blog/article/email-development/emailology_vector_markup_language_and_backgrounds
              rect.style[:'mso-width-percent'] = 1000

            else
              rect.style[:width] = px(width)

            end

            rect.style[:height] = px(height) unless fit_to_shape

            fill = Element.new('v:fill', { :type => '"tile"', :src => outlook_src, :self_close => true })
            fill[:color] = quote(bgcolor) unless none?(bgcolor)

            textbox = Element.new('v:textbox', :inset => '"0,0,0,0"')
            textbox.style[:'mso-fit-shape-to-text'] = 'True' if fit_to_shape

            html << '{outlook-only}'
            html << rect.to_s
            html << fill.to_s
            html << textbox.to_s
            html << '{/outlook-only}'

            # Flag the context as having had VML used within it.
            ctx.vml_used!

          end

          div = Element.new('div')

          # Font family and other attributes get reset within the v:textbox so allow
          # the font series of attributes to be applied.
          mix_font div, opt, ctx

          # Text alignment within the div.
          mix_text_align div, opt, ctx

          html << div.to_s

        end

        html
      end

      private

      # The custom
      MOBILE_SRC = :'mobile-src'

      # These are the parameters that are passed directly from
      # the provided opt to the {table} rendered within the
      # background Helper.
      TABLE_PASSTHRU_OPS = [
          BACKGROUND_POSITION, :border, BORDER_BOTTOM, BORDER_LEFT, BORDER_RADIUS, BORDER_RIGHT,
          BORDER_SPACING, BORDER_TOP, :mobile, MOBILE_BGCOLOR, MOBILE_BACKGROUND, MOBILE_BACKGROUND_COLOR,
          MOBILE_BACKGROUND_IMAGE, MOBILE_BACKGROUND_REPEAT, MOBILE_BACKGROUND_POSITION, MOBILE_SRC,
          MOBILE_BACKGROUND_SIZE
      ]

    end
  end
end
