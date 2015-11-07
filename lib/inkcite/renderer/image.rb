module Inkcite
  module Renderer
    class Image < ImageBase

      def render tag, opt, ctx

        img = Element.new('img', { :border => 0 })

        # Ensure that height and width are defined in the image's attributes.
        mix_dimensions img, opt

        # Get the fully-qualified URL to the image or placeholder image if it's
        # missing from the images directory.
        img[:src] = image_url(opt[:src], opt, ctx)

        mix_background img, opt

        # Check to see if there is alt text specified for this image.  We are
        # testing against nil because sometimes the author desires an empty
        # alt-text attribute.
        alt = opt[:alt]
        if alt

          # Ensure that the alt-tag has quotes around it.
          img[:alt] = quote(alt)

          # The rest of this logic is only appropriate if the alt text
          # is not blank.
          unless alt.blank?

            # Copy the text to the title attribute if enabled for this issue
            img[:title] = img[:alt] if ctx.is_enabled?(COPY_ALT_TO_TITLE)

            # All images with alt text inherit small font unless otherwise specified.
            opt[:font] ||= 'small'

            mix_font img, opt, ctx

          end

        end

        # Images default to block display to prevent unexpected margins in Gmail
        # http://www.campaignmonitor.com/blog/post/3132/how-to-stop-gmail-from-adding-a-margin-to-your-images/
        display = opt[:display] || BLOCK
        img.style[:display] = display unless display == DEFAULT

        # True if the designer wants this image to flow inline.  When true it
        # vertically aligns the image with the text.
        inline = (display == INLINE)

        align = opt[:align] || ('absmiddle' if inline)
        img[:align] = align unless align.blank?

        valign = opt[:valign] || ('middle' if inline)
        img.style[VERTICAL_ALIGN] = valign unless valign.blank?

        mobile_src = opt[:'mobile-src']
        unless mobile_src.blank?

          # Get a unique CSS class name that will be used to swap in the alternate
          # image on mobile.
          klass = klass_name(mobile_src, ctx)

          # Fully-qualify the image URL.
          mobile_src = image_url(mobile_src, opt, ctx)

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

        else

          # Check to see if this image is inside of a mobile-image declaration.
          # If so, the image defaults to hide on mobile.
          mobile = HIDE if mobile.blank? && !ctx.parent_opts(:mobile_image).blank?

        end

        mix_responsive img, opt, ctx, mobile

        img.to_s
      end

      private

      # Name of the property controlling whether or not the alt text should
      # be copied to the title field.
      COPY_ALT_TO_TITLE = :'copy-alt-to-title'

    end
  end
end
