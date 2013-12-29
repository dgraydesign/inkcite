require_relative 'responsive'

# Image swapping technique courtesy of Email on Acid.
# http://www.emailonacid.com/blog/details/C13/a_slick_new_image_swapping_technique_for_responsive_emails
module Inkcite
  class Renderer::MobileImage < Renderer::Base

    include Responsive

    # Image swapping technique
    def render tag, opt, ctx

      tag_stack = ctx.tag_stack(:mobile_image)

      if tag == '/mobile-img'
        tag_stack.pop
        return '</span>'
      end

      tag_stack << opt

      sty = { }
      att = { }

      # True if the image is missing it's dimensions.
      missing_dimensions = false

      # Verify that both dimensions are populated.  Images should always have
      # dimensions provided.
      DIMENSIONS.each { |dim| missing_dimensions = true if (att[dim] = opt[dim].to_i) <= 0 }

      # Background color of the image, if populated.
      bgcolor = opt[:bgcolor] || opt[BACKGROUND_COLOR]
      sty[BACKGROUND_COLOR] = hex(bgcolor) unless bgcolor.blank?

      # Check to see if there is alt text specified for this image.
      # TODO Mobile-only images don't support alt text, yet.
      alt = opt[:alt]

      # Fully-qualify the image path for this version of the email unless it
      # is already includes a full address.
      opt_src = src = opt[:src]
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

      # Don't let an image go into production without dimensions.  Using the original
      # opt[:src] so that we don't display the verbose qualified URL to the developer.
      ctx.error('Missing image dimensions', { :src => opt_src }) if missing_dimensions

      sty[:display] = display = opt[:display] || 'block'

      # True if this image is being displayed inline.
      inline = display == 'inline'

      align = opt[:align] || ('absmiddle' if inline)
      sty[:float] = align unless align.blank?

      valign = opt[:valign] || ('middle' if inline)
      sty[VERTICAL_ALIGN] = valign unless valign.blank?

      # Create a custom klass from the mobile image source name.
      klass = opt_src.downcase.gsub(/[^a-z0-9]/, '')

      sty[BACKGROUND_IMAGE] = "url(#{src})"
      sty[BACKGROUND_REPEAT] = 'no-repeat'
      sty[BACKGROUND_POSITION] = 'center'
      sty[BACKGROUND_SIZE] = '100% auto !important'

      DIMENSIONS.each { |dim| sty[dim] = px(att[dim]) }

      ctx.responsive_styles << css_rule('span', klass, sty)

      return render_tag('span', att.merge({ :class => quote(klass) }))
    end

  end
end
