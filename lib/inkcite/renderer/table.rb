module Inkcite
  module Renderer
    class Table < TableBase

      def render tag, opt, ctx

        html = ''

        # We're either going to be pushing a newly opened table onto this stack
        # or we're popping the open opts off of it.
        tag_stack = ctx.tag_stack(:table)

        if tag == CLOSE_TABLE

          # Grab the opts used to open this table so we can check to see
          # if it had a mobile attribute.
          open_opt = tag_stack.pop

          html << '</tr></table>'

          # Close the Outlook-specific wrapper table opened when the table
          # was declared.
          html << if_mso('</td></tr></table>') if open_opt[:mobile] == FLUID

        else

          # Push this table onto the stack which will make it's declaration
          # available to its child TDs.
          tag_stack << opt

          table = Element.new(tag, { :border => 0, :cellspacing => 0 })

          # Inherit base cell attributes - border, background color and image, etc.
          mix_all table, opt, ctx

          # Text shadowing
          mix_text_shadow table, opt, ctx

          # Conveniently accept padding (easier to type and consistent with CSS)or
          # cellpadding which must always be declared.
          table[:cellpadding] = (opt[:padding] || opt[:cellpadding]).to_i

          # Conveniently accept both float and align to mean the same thing.
          align = opt[:align] || opt[:float]
          table[:align] = align unless align.blank?

          border_radius = opt[BORDER_RADIUS].to_i
          table.style[BORDER_RADIUS] = px(border_radius) if border_radius > 0

          border_collapse = opt[BORDER_COLLAPSE]
          table.style[BORDER_COLLAPSE] = border_collapse unless border_collapse.blank?

          # Apply margins.
          mix_margins table, opt, ctx

          mobile = opt[:mobile]

          if mobile == FLUID

            # Outlook (and Lotus Notes, if you can believe it) doesn't support max-width
            # so we need to wrap the entire fluid table in an Outlook-only table that
            # limits the content within the table to its maximum width.
            html << if_mso(Element.new('table', { :align => opt[:align], :border => 0, :cellspacing => 0, :cellpadding => 0, :width => opt[:width].to_i }).to_s + '<tr><td>')

          elsif mobile == DROP || mobile == SWITCH

            # When a Table is configured to have it's cells DROP then it
            # actually needs to FILL on mobile and it's child Tds will
            # be DROP'd.  Override the local mobile klass so the child Tds
            # see the parent as DROP.
            mobile = FILL

          end

          mix_responsive table, opt, ctx, mobile

          html << table.to_s
          html << '<tr>'
        end

        html
      end

      private

      CLOSE_TABLE = '/table'

    end
  end
end

