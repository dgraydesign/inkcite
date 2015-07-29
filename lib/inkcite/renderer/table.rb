module Inkcite
  module Renderer
    class Table < TableBase

      def render tag, opt, ctx

        tag_stack = ctx.tag_stack(:table)

        if tag == CLOSE_TABLE

          # Remove this table from the stack of previously open tags.
          tag_stack.pop

          return '</tr></table>'

        end

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

        # When a Table is configured to have it's cells DROP then it
        # actually needs to FILL on mobile and it's child Tds will
        # be DROP'd.  Override the local mobile klass so the child Tds
        # see the parent as DROP.
        mobile = FILL if mobile == DROP || mobile == SWITCH

        mix_responsive table, opt, ctx, mobile

        table.to_s + '<tr>'
      end

      private

      CLOSE_TABLE = '/table'

    end
  end
end

