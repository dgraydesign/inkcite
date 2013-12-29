require_relative 'responsive'

module Inkcite
  class Renderer::Image < Renderer::Base

    include Responsive

    def render tag, opt, ctx

      sty = { }
      att = { :border => 0 }

      # True if the image is missing it's dimensions.
      missing_dimensions = false

      # Verify that both dimensions are populated.  Images should always have
      # dimensions provided.
      DIMENSIONS.each { |dim| missing_dimensions = true if (att[dim] = opt[dim].to_i) <= 0 }

      # Background color of the image, if populated.
      bgcolor = opt[:bgcolor] || opt[BACKGROUND_COLOR]
      sty[BACKGROUND_COLOR] = hex(bgcolor) unless bgcolor.blank?

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

      src = opt[:src]

      # Fully-qualify the image path for this version of the email unless it
      # is already includes a full address.
      unless src.include?('://')

        # Verify that the image exists.
        if ctx.assert_image_exists(src)
          if missing_dimensions
            # TODO read the image dimensions from the file and auto-populate
            # the width and height fields.
          end

          # Convert the source (e.g. "cover.jpg") into a fully-qualified reference
          # to the image.  In development this may be images/cover.jpg but in the
          # other environments this would likely be a full URL to the image where it
          # is being hosted.
          src = ctx.image_url(src)

        else

          # As a convenience, replace missing images with placehold.it as long as they
          # meet the minimum dimensions.  No need to spam the design with tiny, tiny
          # placeholders.
          src = "http://placehold.it/#{att[:width]}x#{att[:height]}.#{File.extname(src)}" if DIMENSIONS.all? { |dim| att[dim] > MINIMUM_DIMENSION_FOR_PLACEHOLDER }

        end

      end

      att[:src] = quote(src)

      # Don't let an image go into production without dimensions.  Using the original
      # opt[:src] so that we don't display the verbose qualified URL to the developer.
      ctx.error('Missing image dimensions', { :src => opt[:src] }) if missing_dimensions

      display = opt[:display] || 'block'
      sty[:display] = display unless display == 'default'

      # True if this image is being displayed inline.
      inline = display == 'inline'

      align = opt[:align] || ('absmiddle' if inline)
      att[:align] = align unless align.blank?

      valign = opt[:valign] || ('middle' if inline)
      sty[VERTICAL_ALIGN] = valign unless valign.blank?

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

          att[:class] = FILL

          # Override the inline attributes with scalable width and height.
          ctx.responsive_styles << css_rule(tag, FILL, 'width: 100% !important; height: auto !important;')

        # Hide this image on mobile.
        elsif mobile == HIDE

          att[:class] = HIDE

          # Images that hide on mobile need to have !important because most images get
          # "display: block" inline to properly display in email clients like Gmail.
          ctx.responsive_styles << css_rule(tag, HIDE, 'display: none !important;')

        else
          invalid_mode tag, mobile, ctx

        end

      end

      render_tag(tag, att, sty)
    end

    private

    # By default all images are display: block.
    BLOCK = 'BLOCK'

    # Name of the property controlling whether or not the alt text should
    # be copied to the title field.
    COPY_ALT_TO_TITLE = :'copy-alt-to-title'

    # Both the height and width of the image must exceed this amount in order
    # to get a placehold.it automatically inserted.  Otherwise only an error
    # is raised for missing images.
    MINIMUM_DIMENSION_FOR_PLACEHOLDER = 25

  end
end
