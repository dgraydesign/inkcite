# Image swapping technique courtesy of Email on Acid.
# http://www.emailonacid.com/blog/details/C13/a_slick_new_image_swapping_technique_for_responsive_emails
module Inkcite
  module Renderer
    class MobileImage < ImageBase

      # Image swapping technique
      def render tag, opt, ctx

        tag_stack = ctx.tag_stack(:mobile_image)

        if tag == '/mobile-img'
          tag_stack.pop
          return '</span>'
        end

        tag_stack << opt

        # This is a transient, wrapper Element that we're going to use to
        # style the attributes of the object that will appear when the
        # email is viewed on a mobile device.
        img = Element.new('mobile-img')

        mix_dimensions img, opt, ctx

        mix_background img, opt, ctx

        display = opt[:display]
        img.style[:display] = "#{display}" if display && display != BLOCK && display != DEFAULT

        align = opt[:align]
        img.style[:float] = align unless align.blank?

        # Create a custom klass from the mobile image source name.
        klass = klass_name(opt[:src], ctx)

        src = image_url(opt[:src], opt, ctx)
        img.style[BACKGROUND_IMAGE] = "url(#{src})"

        # Initially, copy the height and width into the CSS so that the
        # span assumes the exact dimensions of the image.
        DIMENSIONS.each { |dim| img.style[dim] = px(opt[dim]) }

        mobile = opt[:mobile]

        # For FILL-style mobile images, override the width.  The height (in px)
        # will ensure that the span displays at a desireable size and the
        # 'cover' attribute will ensure that the image fills the available
        # space ala responsive web design.
        # http://www.campaignmonitor.com/guides/mobile/optimizing-images/
        img.style[:width] = '100%' if mobile == FILL

        # Now visualize a span element
        span = Element.new('span')

        mix_responsive span, opt, ctx, IMAGE

        # Add the class that handles inserting the correct background image.
        ctx.media_query << span.add_rule(Rule.new('span', klass, img.style))

        span.to_s
      end

    end
  end
end

