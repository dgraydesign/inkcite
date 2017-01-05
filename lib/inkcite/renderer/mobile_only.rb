# Fresh thinking on mobile-only content courtesy of FreshInbox's technique
# http://freshinbox.com/blog/bulletproof-solution-to-hiding-mobile-content-when-opened-in-non-mobile-email-clients/
module Inkcite
  module Renderer
    class MobileOnly < Responsive

      def render tag, opt, ctx

        # True if this is the open tag ({mobile-only})
        is_open = tag == 'mobile-only'

        html = ''

        if is_open

          # Intentionally NOT using 'mso-hide: all' version as it requires all
          # nested tables to have that attribute applied. Why have all that extra
          # markup - just use this simple conditional instead.
          html << '{if-not test="mso 9"}'

          # These elements style the div such that it is invisible in all
          # other major email clients.
          div = Element.new('div')
          div.style[:display] = 'none'
          div.style[:'max-height'] = 0
          div.style[:'overflow'] = 'hidden'

          klass = opt[:inline] ? 'show-inline' : 'show'
          mix_responsive_klass div, opt, ctx, klass

          html << div.to_s

        else

          # Close the div
          html << '</div>'

          # Close the outlook conditional for the close tag.
          html << '{/if-not}'

        end

        html
      end

    end
  end
end
