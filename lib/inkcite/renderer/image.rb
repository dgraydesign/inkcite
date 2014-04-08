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

        # Check to see if there is alt text specified for this image.
        alt = opt[:alt]
        unless alt.blank?

          # Ensure that the alt-tag has quotes around it.
          img[:alt] = quote(alt)

          # Copy the text to the title attribute if enabled for this issue
          img[:title] = img[:alt] if ctx.is_enabled?(COPY_ALT_TO_TITLE)

          # All images with alt text inherit small font unless otherwise specified.
          opt[:font] ||= 'small'

          mix_font img, opt, ctx

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
          img.classes << klass = klass_name(mobile_src, ctx)

          # Fully-qualify the image URL.
          mobile_src = image_url(mobile_src, opt, ctx)

          # Add a responsive rule that replaces the image with a different source
          # with the same dimensions.  Warning, this isn't supported on earlier
          # versions of iOS 6 and Android 4.
          # http://www.emailonacid.com/forum/viewthread/404/
          ctx.responsive_styles << Rule.new(tag, klass, "content: url(#{mobile_src}) !important;")

        end

        mobile = opt[:mobile]

        # Check to see if this image is inside of a mobile-image declaration.
        # If so, the image defaults to hide on mobile.
        mobile = HIDE if mobile.blank? && !ctx.parent_opts(:mobile_image).blank?

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
