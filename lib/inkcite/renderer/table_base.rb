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
        if !bgcolor.blank? && bgcolor != NONE
          bgcolor = hex(bgcolor)

          element[:bgcolor] = bgcolor
          element.style[BACKGROUND_COLOR] = bgcolor

        end

        # Assisted background image handling for maximum compatibility.
        bgimage = opt[:background]
        unless bgimage.blank?
          if ctx.assert_image_exists(bgimage)

            # Fully-qualify the image path
            bgimage = ctx.image_url(bgimage)

            repeat = opt[BACKGROUND_REPEAT]
            position = opt[BACKGROUND_POSITION]

            # Default to no-repeat if a position has been supplied or replace
            # 'none' as a convenience (cause none is easier to type than no-repeat).
            repeat = 'no-repeat' if (repeat.blank? && !position.blank?) || repeat == NONE

            # Style up the background image.
            element.style[BACKGROUND_IMAGE] = "url('#{bgimage}')"
            element.style[BACKGROUND_REPEAT] = repeat unless repeat.blank?
            element.style[BACKGROUND_POSITION] = position unless position.blank?

            # Can't gracefully degrade if anything other than repeat is specified
            # for the background image.
            element[:background] = quote(bgimage) if repeat.blank?

          end
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

    end
  end
end
