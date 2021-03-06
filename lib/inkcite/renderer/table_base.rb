module Inkcite
  module Renderer
    class TableBase < Responsive

      protected

      # Returns cellpadding specified from the provided attributes by
      # Checking both :padding and :cellpadding.
      def get_padding opt
        (opt[:padding] || opt[:cellpadding]).to_i
      end

      def mix_all element, opt, ctx

        mix_animation element, opt, ctx
        mix_background element, opt, ctx
        mix_border element, opt, ctx
        mix_dimensions element, opt, ctx
        mix_margins element, opt, ctx

      end

      def mix_background element, opt, ctx

        bgcolor = detect_bgcolor(opt)

        # Set the bgcolor attribute of the element as a fallback if
        # css isn't supported.
        element[:bgcolor] = bgcolor unless bgcolor.nil?

        # Allow background gradients on tables and tds.
        mix_background_gradient element, opt, ctx

        bgimage    = opt[:background]
        bgposition = opt[BACKGROUND_POSITION]
        bgrepeat   = opt[BACKGROUND_REPEAT]
        bgsize     = opt[BACKGROUND_SIZE]

        # Sets the background image attributes in the element's style
        # attribute.  These values take precedence on the desktop
        # version of the email.
        desktop_background = mix_background_shorthand(
            bgcolor,
            bgimage,
            bgposition,
            bgrepeat,
            bgsize,
            ctx
        )

        element.style[:background] = desktop_background unless bgimage.blank?

        # Set the mobile background image attributes.  These values take
        # precedence on the mobile version of the email.  If unset the
        # mobile version inherits from the desktop version.
        mobile_background = mix_background_shorthand(
            detect(opt[MOBILE_BACKGROUND_COLOR], opt[MOBILE_BGCOLOR], bgcolor),
            detect(opt[MOBILE_BACKGROUND_IMAGE], opt[MOBILE_BACKGROUND], opt[MOBILE_SRC], bgimage),
            detect(opt[MOBILE_BACKGROUND_POSITION], bgposition),
            detect(opt[MOBILE_BACKGROUND_REPEAT], bgrepeat),
            detect(opt[MOBILE_BACKGROUND_SIZE], bgsize),
            ctx
        )

        if !mobile_background.blank? && mobile_background != desktop_background
          element.mobile_style[:background] = mobile_background
        end

      end

      def mix_dimensions element, opt, ctx

        # Not taking .to_i because we want to accept both integer values
        # or percentages - e.g. 50%
        width = opt[:width]
        element[:width] = width unless width.blank?

        mobile_width = opt[MOBILE_WIDTH]
        element.mobile_style[:width] = px(mobile_width) unless none?(mobile_width)

        height = opt[:height].to_i
        element[:height] = height if height > 0

        mobile_height = opt[MOBILE_HEIGHT]
        element.mobile_style[:height] = px(mobile_height) unless none?(mobile_height)

      end

      private

      def mix_background_shorthand bgcolor, img, position, repeat, size, ctx

        values = []

        values << hex(bgcolor) unless none?(bgcolor)

        unless img.blank?

          # If no image has been provided or if the image provided is equal
          # to "none" then we'll set the values independently.  Otherwise
          # we'll use a composite background declaration.
          if none?(img)
            values << 'none'

          else

            values << "url(#{ctx.image_url(img)})"

            position = '0% 0%' if position.blank? && !size.blank?
            unless position.blank?
              values << position
              unless size.blank?
                values << '/'
                values << (size == 'fill' ? '100% auto' : size)
              end
            end

            # Default to no-repeat if a position has been supplied or replace
            # 'none' as a convenience (cause none is easier to type than no-repeat).
            repeat = 'no-repeat' if (repeat.blank? && !position.blank?) || repeat == NONE
            values << repeat unless repeat.blank?

          end

        end

        values.blank?? nil : values.join(' ')
      end

    end
  end
end
