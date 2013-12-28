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
          src = "http://placehold.it/#{att[:width]}x#{att[:height]}.#{File.extname(src)}" if DIMENSIONS.all? { |dim| att[dim] > 25 }

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

      html = ''

      mobile = responsive_mode(opt)
      if mobile

        if mobile == SWAP

          mobile_src = opt[ON_MOBILE_SRC] || opt[MOBILE_SRC]
          if mobile_src

            # Create a custom klass from the mobile image source name.
            klass = mobile_src.downcase.gsub(/[^a-z0-9]/, '')

            mobile_width = opt[MOBILE_WIDTH].to_i
            mobile_height = opt[MOBILE_HEIGHT].to_i

            html << render_tag('span', { :class => klass })

            # Placeholder the mobile image if it doesn't exists.
            mobile_src = "http://placehold.it/#{mobile_width}x#{mobile_height}.#{File.extname(mobile_src)}" unless ctx.assert_image_exists(mobile_src)

            ctx.responsive_styles << css_rule('span', klass, render_styles({
                :display => 'block',
                :width => '100% important!',
                :height => "#{(mobile_height / mobile_width * 100).round.to_i}% important!",
                BACKGROUND_IMAGE => "url(#{ctx.image_url(mobile_src)})",
                BACKGROUND_SIZE  => '100% auto !important'
            }))

          else
            ctx.error 'Responsive image missing mobile src', { :src => src, :mobile_src => mobile_src }
          end

        end

        # Hide this image on mobile.
        if mobile == FILL

          att[:class] = FILL

          # Override the inline attributes with scalable width and height.
          ctx.responsive_styles << css_rule(tag, FILL, 'width: 100% !important; height: auto !important;')

        elsif mobile == HIDE || mobile == SWAP

          att[:class] = HIDE

          # Images that hide on mobile need to have !important because most images get
          # "display: block" inline to properly display in email clients like Gmail.
          ctx.responsive_styles << css_rule(tag, HIDE, 'display: none !important;')

        else
          invalid_mode tag, mobile, ctx

        end

      end

      html << render_tag(tag, att, sty)

      # Close the wrapper around the mobile image swapper.
      html << render_tag('/span') if mobile == SWAP

      html
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

    # Convenient.
    DIMENSIONS = [ :width, :height ]

    # Mobile styles
    HIDE = 'hide'

    ON_MOBILE_SRC = :'on-mobile-src'
    MOBILE_SRC = :'mobile-src'
    MOBILE_WIDTH = :'mobile-width'
    MOBILE_HEIGHT = :'mobile-height'

  end
end
