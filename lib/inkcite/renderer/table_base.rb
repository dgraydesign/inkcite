module Inkcite
  module Renderer
    class TableBase < Responsive

      protected

      def mix_all element, opt, ctx

        mix_background element, opt, ctx
        mix_border element, opt, ctx
        mix_dimensions element, opt, ctx

      end

      def mix_background element, opt, ctx

        bgcolor = opt[:bgcolor]
        bgcolor = nil if bgcolor == NONE

        # Set the bgcolor attribute of the element as a fallback if
        # css isn't supported.
        element[:bgcolor] = bgcolor unless bgcolor.blank?

        # Assisted background image handling for maximum compatibility.
        bgimage  = opt[:background]

        background_css(element.style, bgcolor, bgimage, opt[BACKGROUND_POSITION], opt[BACKGROUND_REPEAT], false, ctx)

        m_bgcolor = opt[MOBILE_BACKGROUND_COLOR]
        m_bgimage = opt[MOBILE_BACKGROUND_IMAGE]

        mobile_background = background_css(
            {},
            m_bgcolor,
            m_bgimage,
            opt[MOBILE_BACKGROUND_POSITION],
            opt[MOBILE_BACKGROUND_REPEAT],
            (m_bgcolor && bgcolor) || (m_bgimage && bgimage),
            ctx
        )

        unless mobile_background.blank?

          # Add the responsive rule that applies to this element.
          rule = Rule.new(element.tag, unique_klass(ctx), mobile_background)

          # Add the rule to the view
          ctx.responsive_styles << rule

          # Add the responsive klass to the
          element.classes << rule.klass

        end

      end

      def mix_border element, opt, ctx

        border = opt[:border]
        element.style[:border] = border unless border.blank?

        # Iterate through each of the possible borders and apply them individually
        # to the style if they are defined.
        DIRECTIONS.each do |dir|
          key = :"border-#{dir}"
          border = opt[key]
          element.style[key] = border unless border.blank? || border == NONE
        end

      end

      def mix_dimensions element, opt, ctx

        # Not taking .to_i because we want to accept both integer values
        # or percentages - e.g. 50%
        width = opt[:width]
        element[:width] = width unless width.blank?

        height = opt[:height].to_i
        element[:height] = height if height > 0

      end

      private

      def background_css into, bgcolor, img, position, repeat, important, ctx
        unless bgcolor.blank? && img.blank?

          bgcolor = hex(bgcolor) unless bgcolor.blank?

          # There is only a background color so set that explicitly.
          if img.blank?
            bgcolor = "#{bgcolor} !important" if important
            into[BACKGROUND_COLOR] = bgcolor

          else

            # Default to no-repeat if a position has been supplied or replace
            # 'none' as a convenience (cause none is easier to type than no-repeat).
            repeat = 'no-repeat' if (repeat.blank? && !position.blank?) || repeat == NONE

            sty = []
            sty << bgcolor unless bgcolor.blank?

            if ctx.assert_image_exists(img)
              sty << "url(#{ctx.image_url(img)})"
              sty << position unless position.blank?
              sty << repeat unless repeat.blank?
            end

            sty << '!important' if important

            into[:background] = sty.join(' ')
          end

        end

        into
      end

    end
  end
end
