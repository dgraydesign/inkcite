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

        sty = {}
        att = {}

        mix_dimensions opt, att

        mix_background opt, sty

        # Check to see if there is alt text specified for this image.
        # TODO Mobile-only images don't support alt text, yet.
        alt = opt[:alt]

        # Images default to block display to prevent unexpected margins in Gmail
        # http://www.campaignmonitor.com/blog/post/3132/how-to-stop-gmail-from-adding-a-margin-to-your-images/
        display = opt[:display] || BLOCK
        sty[:display] = "#{display} !important" unless display == DEFAULT

        align = opt[:align]
        sty[:float] = align unless align.blank?

        valign = opt[:valign] || ('middle' if display == INLINE)
        sty[VERTICAL_ALIGN] = valign unless valign.blank?

        # Create a custom klass from the mobile image source name.
        klass = klass_name(opt[:src])

        src = image_url(opt[:src], att, ctx)
        sty[BACKGROUND_IMAGE] = "url(#{src})"
        sty[BACKGROUND_POSITION] = 'center'
        sty[BACKGROUND_SIZE] = 'cover'

        # Initially, copy the height and width into the CSS so that the
        # span assumes the exact dimensions of the image.
        DIMENSIONS.each { |dim| sty[dim] = px(att[dim]) }

        mobile = responsive_mode(opt)

        # For FILL-style mobile images, override the width.  The height (in px)
        # will ensure that the span displays at a desireable size and the
        # 'cover' attribute will ensure that the image fills the available
        # space ala responsive web design.
        # http://www.campaignmonitor.com/guides/mobile/optimizing-images/
        sty[:width] = '100%' if mobile == FILL

        ctx.responsive_styles << css_rule('span', klass, sty)

        render_tag('span', { :class => quote(klass) })
      end

    end
  end
end

