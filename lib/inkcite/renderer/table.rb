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

        att = { :border => 0, :cellspacing => 0 }
        sty = {}

        # Inherit base cell attributes - border, background color and image, etc.
        mix_all opt, att, sty, ctx

        # Text shadowing
        mix_text_shadow opt, sty, ctx

        # As a convenience to people used to typing 'cellpadding' on tables.
        opt[:padding] ||= opt[:cellpadding]

        padding = opt[:padding].to_i
        att[:cellpadding] = padding

        # Conveniently accept both float and align to mean the same thing.
        align = opt[:align] || opt[:float]
        att[:align] = align unless align.blank?

        border_radius = opt[BORDER_RADIUS].to_i
        sty[BORDER_RADIUS] = px(border_radius) if border_radius > 0

        margin_top = opt[MARGIN_TOP].to_i
        sty[MARGIN_TOP] = px(margin_top) if margin_top > 0

        mobile = responsive_mode(opt)
        if mobile

          # When a table's cells will drop (or stack) the parent table needs
          # to fill the entire screen.
          mobile = FILL if mobile == DROP

          mix_responsive tag, mobile, att, ctx

        end

        render_tag(tag, att, sty) + '<tr>'
      end

      private

      CLOSE_TABLE = '/table'

    end
  end
end

