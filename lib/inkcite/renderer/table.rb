module Inkcite
  module Renderer
    class Table < TableBase

      def render tag, opt, ctx

        html = ''

        # We're either going to be pushing a newly opened table onto this stack
        # or we're popping the open opts off of it.
        tag_stack = ctx.tag_stack(:table)

        if tag == CLOSE_TABLE

          # Pop the opts used when the table was originally opened.  Then grab the
          # mobile attribute. If this is a fluid table, we'll need to do close some
          # of the additional tags injected when it was opened.
          open_opt = tag_stack.pop
          open_mobile = open_opt[:mobile]

          # If the table was declared as Fluid-Hybrid Drop, then there are some additional
          # elements that need to be closed before the regular row-table closure that
          # the Table helper normally produces.
          if open_mobile == FLUID_DROP

            # Close the interior conditional table for Outlook that contains the floating blocks.
            html << if_mso('</tr></table>')

            # Close what @campaignmonitor calls the "secret weapon" cell that typically aligns
            # the text horizontally and vertically aligns the floating elements.
            html << '</td>' # Styled
          end

          # Normal Inkcite Helper close HTML.
          html << '</tr></table>'

          # Close the conditional table for Output that contains the entire fluid layout.
          html << if_mso('</td></tr></table>') if is_fluid?(open_mobile)

        else

          # Push this table onto the stack which will make it's declaration
          # available to its child TDs.
          tag_stack << opt

          table = Element.new(tag, { :border => 0, :cellspacing => 0 })

          # Grab the responsive mobile klass that is assigned to this table, if any.
          mobile = opt[:mobile]

          # Check if fluid-drop has been specified.  This will force a lot more HTML to
          # be produced for this table and its child TDs.
          is_fluid_drop = mobile == FLUID_DROP

          # Inherit base cell attributes - border, background color and image, etc.
          mix_all table, opt, ctx
          mix_margins table, opt, ctx
          mix_text_shadow table, opt, ctx

          # Conveniently accept padding (easier to type and consistent with CSS) or
          # cellpadding which must always be declared.
          #
          # If Fluid-Drop is enabled, padding is always zero at this top-level table
          # and will be applied in the TD renderer when it creates a new table to
          # wrap itself in.
          table[:cellpadding] = is_fluid_drop ? 0 : get_padding(opt)

          # Conveniently accept both float and align to mean the same thing.
          align = opt[:align] || opt[:float]
          table[:align] = align unless align.blank?

          border_radius = opt[BORDER_RADIUS].to_i
          table.style[BORDER_RADIUS] = px(border_radius) if border_radius > 0

          border_collapse = opt[BORDER_COLLAPSE]
          table.style[BORDER_COLLAPSE] = border_collapse unless border_collapse.blank?


          # For both fluid and fluid-drop share certain setup which is performed here.
          if is_fluid?(mobile)

            # Width must always be specified on fluid tables, like it is for images.
            # Warn the designer if a width has not been supplied in pixels.
            width = opt[:width].to_i
            ctx.error("Width is a required attribute when '#{mobile}' is applied to a {table}", opt) unless width > 0

            # Fluid table method courtesy of @campaignmonitor - assign the max-width in
            # pixels and set the normal width to 100%.
            # https://www.campaignmonitor.com/blog/email-marketing/2014/07/creating-a-centred-responsive-design-without-media-queries/
            table.style[MAX_WIDTH] = px(width)
            table[:width] = '100%'

            # Outlook (and Lotus Notes, if you can believe it) doesn't support max-width
            # so we need to wrap the entire fluid table in a conditional table that
            # ensures layout displays within the actual maximum pixels width.
            html << if_mso(Element.new('table', {
                        :align => opt[:align], :border => 0, :cellspacing => 0, :cellpadding => 0, :width => opt[:width].to_i
                    }) + '<tr><td>')

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

          if is_fluid_drop

            # Fluid-Drop tables need a default alignment specified which is inherited
            # by the child TD elements if not otherwise specified.
            #
            # 11/8/2015: For reasons I don't understand, if the table is not valigned
            # middle by default, then we lose the ability to valign-middle individual
            # TD children.  So, if we force 'middle' here, then the TDs can override
            # with 'top' or 'bottom' alignment when desired.
            valign = opt[:valign] ||= 'middle'

            # According to @campaignmonitor this is the secret weapon of Fluid-Hyrbid
            # drop which wraps the floating elements and centers them appropriately.
            # https://www.campaignmonitor.com/blog/email-marketing/2014/07/creating-a-centred-responsive-design-without-media-queries/
            #
            # The zero-size font addresses a rendering problem in Outlook:
            # https://css-tricks.com/fighting-the-space-between-inline-block-elements/
            html << Element.new('td', :style => { TEXT_ALIGN => :center, VERTICAL_ALIGN => opt[:valign], FONT_SIZE => 0 }).to_s

            # Lastly, Outlook needs yet another conditional table that will be used
            # to contain the floating blocks.  The TD elements are generated by
            # each of the columns within this Fluid-Drop table.
            html << if_mso(Element.new('table', :width => '100%', :align => :center, :cellpadding => 0, :cellspacing => 0, :border => 0) + '<tr>')

          end

        end

        html
      end

      CLOSE_TABLE = '/table'

    end
  end
end

