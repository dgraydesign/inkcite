module Inkcite
  module Renderer
    class Image < ImageBase

      def render tag, opt, ctx

        sty = { }
        att = { :border => 0 }

        # Ensure that height and width are defined in the image's attributes.
        mix_dimensions opt, att

        # Get the fully-qualified URL to the image or placeholder image if it's
        # missing from the images directory.
        att[:src] = image_url(opt[:src], att, ctx)

        mix_background opt, sty

        # Check to see if there is alt text specified for this image.
        alt = opt[:alt]
        unless alt.blank?

          # Ensure that the alt-tag has quotes around it.
          att[:alt] = quote(alt)

          # Copy the text to the title attribute if enabled for this issue
          att[:title] = att[:alt] if ctx.is_enabled?(COPY_ALT_TO_TITLE)

          # All images with alt text inherit small font unless otherwise specified.
          font = opt[:font] || 'small'
          unless font == NONE

            size = opt[FONT_SIZE] || ctx["#{font}-font-size"]
            sty[FONT_SIZE] = px(size)

            color = opt[:color] || ctx["#{font}-color"]
            sty[:color] = hex(color) unless color.blank?

          end

          # Text shadowing
          mix_text_shadow opt, sty, ctx

        end

        # Images default to block display to prevent unexpected margins in Gmail
        # http://www.campaignmonitor.com/blog/post/3132/how-to-stop-gmail-from-adding-a-margin-to-your-images/
        display = opt[:display] || BLOCK
        sty[:display] = display unless display == DEFAULT

        # True if the designer wants this image to flow inline.  When true it
        # vertically aligns the image with the text.
        inline = (display == INLINE)

        align = opt[:align] || ('absmiddle' if inline)
        att[:align] = align unless align.blank?

        valign = opt[:valign] || ('middle' if inline)
        sty[VERTICAL_ALIGN] = valign unless valign.blank?

        klasses = []
        klasses = []

        mobile_src = opt[:'mobile-src']
        unless mobile_src.blank?

          # Get a unique CSS class name that will be used to swap in the alternate
          # image on mobile.
          klass = klass_name(mobile_src)
          klasses << klass

          # Fully-qualify the image URL.
          mobile_src = image_url(mobile_src, att, ctx)

          # Add a responsive rule that replaces the image with a different source
          # with the same dimensions.  Warning, this isn't supported on earlier
          # versions of iOS 6 and Android 4.
          # http://www.emailonacid.com/forum/viewthread/404/
          ctx.responsive_styles << css_rule(tag, klass, "content:url(#{mobile_src}) !important;")

        end

        mobile = responsive_mode(opt)
        if !mobile

          # Check to see if this image is inside of a mobile image declaration.
          # If so, the image defaults to hide on mobile.
          parent = ctx.tag_stack(:mobile_image).opts
          mobile = HIDE unless parent.nil?

        end

        if mobile

          # Scale the image to fill available space.
          if mobile == FILL

            klasses << FILL

            # Override the inline attributes with scalable width and height.
            ctx.responsive_styles << css_rule(tag, FILL, 'width: 100% !important; height: auto !important;')

          # Hide this image on mobile.
          elsif mobile == HIDE

            klasses << HIDE

            # Images that hide on mobile need to have !important because most images get
            # "display: block" inline to properly display in email clients like Gmail.
            ctx.responsive_styles << css_rule(tag, HIDE, 'display: none !important;')

          else
            invalid_mode tag, mobile, ctx

          end

        end

        att[:class] = quote(klasses.join(' ')) unless klasses.blank?

        render_tag(tag, att, sty)
      end

      private

      # Name of the property controlling whether or not the alt text should
      # be copied to the title field.
      COPY_ALT_TO_TITLE = :'copy-alt-to-title'

    end
  end
end
