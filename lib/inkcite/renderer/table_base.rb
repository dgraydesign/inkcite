module Inkcite
  module Renderer
    class TableBase < Responsive

      protected

      def mix_all opt, att, sty, ctx

        mix_background(opt, att, sty, ctx)
        mix_border(opt, att, sty, ctx)
        mix_dimensions(opt, att, sty, ctx)

      end

      def mix_background opt, att, sty, ctx

        bgcolor = opt[:bgcolor]
        if !bgcolor.blank? && bgcolor != NONE
          bgcolor = hex(bgcolor)
          att[:bgcolor] = bgcolor
          sty[BACKGROUND_COLOR] = bgcolor
        end

        # Assisted background image handling for maximum compatibility.
        bgimage = opt[:background]
        unless bgimage.blank?
          if ctx.assert_image_exists(bgimage)

            # Fully-qualify the image path
            bgimage = ctx.image_url(bgimage)

            repeat = opt[BACKGROUND_REPEAT]
            position = opt[BACKGROUND_POSITION]

            # Default to no-repeat if a position has been supplied
            repeat = 'no-repeat' if repeat.blank? && !position.blank?

            # Style up the background image.
            sty[BACKGROUND_IMAGE] = "url('#{bgimage}')"
            sty[BACKGROUND_REPEAT] = repeat unless repeat.blank?
            sty[BACKGROUND_POSITION] = position unless position.blank?

            # Can't gracefully degrade if anything other than repeat is specified
            # for the background image.
            att[:background] = quote(bgimage) if repeat.blank?

          end
        end

      end

      def mix_border opt, att, sty, ctx

        border = opt[:border]
        sty[:border] = border unless border.blank?

        # Iterate through each of the possible borders and apply them individually
        # to the style if they are defined.
        DIRECTIONS.each do |dir|
          key = :"border-#{dir}"
          border = opt[key]
          sty[key] = border unless border.blank? || border == NONE
        end

      end

      def mix_dimensions opt, att, sty, ctx

        # Not taking .to_i because we want to accept both integer values
        # or percentages - e.g. 50%
        width = opt[:width]
        att[:width] = width unless width.blank?

        height = opt[:height].to_i
        if height > 0
          att[:height] = height
          #sty[:height] = px(height)
        end

      end

    end
  end
end
