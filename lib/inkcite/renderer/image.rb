module Inkcite
  module Renderer
    class Image < ImageBase

      def render tag, opt, ctx

        img = Element.new('img', { :border => 0 })

        # Ensure that height and width are defined in the image's attributes.
        mix_dimensions img, opt, ctx

        mix_background img, opt, ctx
        mix_border img, opt, ctx
        mix_margins img, opt, ctx

        # Check to see if there is alt text specified for this image.  We are
        # testing against nil because sometimes the author desires an empty
        # alt-text attribute.
        alt = opt[:alt]
        if alt

          # Allow "\n" to be placed within alt text and converted into a line
          # break for convenience.
          alt.gsub!('\n', "\n")

          # Need to add an extra space for the email clients (ahem, Gmail,
          # cough) that don't support alt text with line breaks.
          alt.gsub!("\n", " \n")

          # Remove all HTML from the alt text.  Ran into a situation where a
          # custom Helper was applying styled text as image alt text.  Since
          # HTML isn't allowed within alt text, as a convenience we'll just
          # delete said markup.
          alt.gsub!(/<[^>]*>/, '')

          # Ensure that the alt-tag has quotes around it.
          img[:alt] = quote(alt)

          # The rest of this logic is only appropriate if the alt text
          # is not blank.
          unless alt.blank?

            # Copy the text to the title attribute if enabled for this issue
            img[:title] = img[:alt] if ctx.is_enabled?(COPY_ALT_TO_TITLE)

            mix_font img, opt, ctx

            text_align = opt[TEXT_ALIGN]
            img.style[TEXT_ALIGN] = text_align unless text_align.blank?

            # Check to see if the alt text contains line breaks.  If so, automatically add
            # the white-space style set to 'pre' which forces the alt text to render with
            # that line breaks visible.
            # https://litmus.com/community/discussions/418-line-breaks-within-alt-text
            img.style[WHITE_SPACE] = 'pre' if alt.match(/[\n\r\f]/)

          end

        end

        # Images default to block display to prevent unexpected margins in Gmail
        # http://www.campaignmonitor.com/blog/post/3132/how-to-stop-gmail-from-adding-a-margin-to-your-images/
        display = opt[:display] || BLOCK
        img.style[:display] = display unless display == DEFAULT

        # True if the designer wants this image to flow inline.  When true it
        # vertically aligns the image with the text.
        inline = (display == INLINE)

        # Allow max-height to be specified.
        max_height = opt[MAX_HEIGHT]
        img.style[MAX_HEIGHT] = px(max_height) unless max_height.blank?

        align = opt[:align] || ('absmiddle' if inline)
        img[:align] = align unless align.blank?

        valign = opt[:valign] || ('middle' if inline)
        img.style[VERTICAL_ALIGN] = valign unless valign.blank?

        # Fix for unexpected whitespace underneath images when emails
        # are viewed in Outlook.com.  Thanks to @HTeuMeuLeu
        # https://emails.hteumeuleu.com/outlook-coms-latest-bug-and-how-to-fix-gaps-under-images-ee1816671461
        id = ctx.unique_id :img
        img[:id] = quote("OWATemporaryImageDivContainer#{id}")

        html = ''

        # Check to see if an outlook-specific image source has been
        # specified - typically used when there is an animated gif as
        # the main source but a static image for Outlook clients.
        outlook_src = opt[OUTLOOK_SRC]
        unless outlook_src.blank?

          # Initially set the image's URL to the outlook-specific image.
          img[:src] = image_url(outlook_src, opt, ctx)

          # Wrap the image in the outlook-specific conditionals.
          html << if_mso(img)
          html << '{not-outlook}'

        end

        # Get the fully-qualified URL to the image or placeholder image if it's
        # missing from the images directory.
        img[:src] = image_url(opt[:src], opt, ctx)

        mobile_src = opt[:'mobile-src']
        unless mobile_src.blank?

          # Get a unique CSS class name that will be used to swap in the alternate
          # image on mobile.
          klass = klass_name(mobile_src, ctx)

          # Fully-qualify the image URL.
          mobile_src = image_url(mobile_src, opt, ctx, false)

          # Add a responsive rule that replaces the image with a different source
          # with the same dimensions.  Warning, this isn't supported on earlier
          # versions of iOS 6 and Android 4.
          # http://www.emailonacid.com/forum/viewthread/404/
          ctx.media_query << img.add_rule(Rule.new(tag, klass, "content: url(#{mobile_src}) !important;"))

        end

        mobile = opt[:mobile]

        # Fluid-Hybrid responsive images courtesy of @moonstrips and @CourtFantinato.
        # http://webdesign.tutsplus.com/tutorials/creating-a-future-proof-responsive-email-without-media-queries--cms-23919#comment-2074740905
        if mobile == FLUID

          # Set the inline styles of the image to scale with aspect ratio
          # intact up to the maximum width of the image itself.
          img.style[MAX_WIDTH] = px(opt[:width])
          img.style[:width] = '100%'
          img.style[:height] = 'auto'

          # Leave the explicit width attribute set (this prevents Outlook from
          # blowing up) but clear the height attribute as Gmail images will not
          # maintain aspect ratio if present.
          img[:height] = nil

        end

        mix_responsive img, opt, ctx, mobile

        html << img.to_s

        # Conclude the outlook-specific conditional if opened.
        html << '{/not-outlook}' unless outlook_src.blank?

        html
      end

      private

      # Name of the property controlling whether or not the alt text should
      # be copied to the title field.
      COPY_ALT_TO_TITLE = :'copy-alt-to-title'

    end
  end
end
