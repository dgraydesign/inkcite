module Inkcite
  module Renderer
    class Td < TableBase

      def render tag, opt, ctx

        html = ''

        # Tracks the depth of currently open TD elements.
        tag_stack = ctx.tag_stack(:td)

        # Grab the attributes of the parent table so that the TD can inherit
        # specific values like padding, valign, responsiveness, etc.
        table_opt = ctx.parent_opts(:table)
        table_mobile = table_opt[:mobile]

        # Check to see if the parent table was set to fluid-drop which causes
        # the table cells to be wrapped in <div> elements and floated to
        # cause them to display more responsively on Android Mail and Gmail apps.
        #
        # Fluid-Hybrid TD courtesy of @moonstrips and our friends at Campaign Monitor
        # https://www.campaignmonitor.com/blog/email-marketing/2014/07/creating-a-centred-responsive-design-without-media-queries/
        is_fluid_drop = is_fluid_drop?(table_mobile)

        if tag == CLOSE_TD

          # Retrieve the opts that were used to open this TD.
          open_opt = tag_stack.pop

          # Normal HTML produced by the Helper to close the cell.
          html << '</td>'

          # If the td was originally opened with fluid-drop, we need to do a fair
          # bit of cleanup...
          if is_fluid_drop

            # Close the
            html << '</tr></table>'

            # Close the floating, responsive div.
            html << '{/div}'

            # Close the conditional cell
            html << if_mso('</td>')

          end

        else

          # Push this tag onto the stack so that child elements (e.g. links)
          # can have access to its attributes.
          tag_stack << opt

          td = Element.new('td')

          # Check to see if a width has been specified for this element.  The
          # width is critical to Fluid-Hybrid drop.
          width = opt[:width].to_i

          # Check for vertical alignment applied to either the TD or to the
          # parent Table.
          valign = detect(opt[:valign], table_opt[:valign])
          td[:valign] = valign unless valign.blank?

          # It is a best-practice to declare the same padding on all cells in a
          # table.  Check to see if padding was declared on the parent.
          padding = get_padding(table_opt)
          td.style[:padding] = px(padding) if padding > 0

          # Apply the no-wrap attribute if provided.
          td[:nowrap] = true if opt[:nowrap]

          mobile = opt[:mobile]

          # If the table defines mobile-padding, then apply the correct mobile
          # style to this td - and its !important if there is padding on
          # the td already.
          unless mobile == HIDE
            mix_mobile_padding td, table_opt, ctx
            mix_mobile_padding td, opt, ctx
          end

          # Need to handle Fluid-Drop HTML injection here before the rest of the
          # TD is formalized.  Fluid-Drop removes the width attribute of the cell
          # as it is wrapped in a 100%-width table.
          if is_fluid_drop

            # Width must be specified for Fluid-Drop cells.  Vertical-alignment is
            # also important but should have been preset by the Table Helper if it
            # was omitted by the designer.
            ctx.error("Width is a required attribute when #{table_mobile} is specified", opt) unless width > 0
            ctx.error("Vertical alignment should be specified when #{table_mobile} is specified", opt) if valign.blank?

            # Conditional Outlook cell to prevent the 100%-wide table within from
            # stretching beyond the max-width.  Also, valign necessary to get float
            # elements to align properly.
            html << if_mso(Element.new('td', :width => width, :valign => valign))

            # Per @campaignmonitor, the secret to the Fluid-Drop trick is to wrap the
            # floating table in a div with "display: inline-block" - which means that
            # they'll obey the text-align property on the parent cell (text-align affects
            # all inline or inline-block elements in a container).
            # https://www.campaignmonitor.com/blog/email-marketing/2014/07/creating-a-centred-responsive-design-without-media-queries/

            div_mobile = mobile == HIDE ? HIDE : FILL
            html << %Q({div width=#{width} display=inline-block valign=#{valign} mobile="#{div_mobile}"})

            # One last wrapper table within the div.  This 100%-wide table is also where any
            # padding applied to the elements belongs.
            html << Element.new('table', :cellpadding => padding, :cellspacing => 0, :border => 0, :width => '100%').to_s
            html << '<tr>'

            # Remove the width attribute from the TDs declaration.
            opt.delete(:width)

            # The TD nested within the floating div and additional table will inherit center-aligned
            # text which means fluid-drop cells would have a default layout inconsistent with a regular
            # TD - which will typically be left-aligned.  So, unless otherwise specified, presume that
            # the TD should have left-aligned text.
            opt[:align] = 'left' if opt[:align].blank?

            mobile = ''

          end

          # Inherit base cell attributes - border, background color and image, etc.
          mix_all td, opt, ctx

          # Force the td to collapse to a single pixel to support images that
          # are less than 15 pixels.
          opt.merge!({
                  :font => NONE,
                  :color => NONE,
                  FONT_SIZE => 1,
                  LINE_HEIGHT => 1
              }) if opt[:flush]

          # Custom handling for text align on TDs rather than Base's mix_text_align
          # because if possible, using align= rather than a style keeps emails
          # smaller.  But for left-aligned text, you gotta use a style because
          # you know, Outlook.
          align = opt[:align]
          unless align.blank?
            td[:align] = align

            # Must use style to reinforce left-align text in certain email clients.
            # All other alignments are accepted naturally.
            td.style[TEXT_ALIGN] = align if align == LEFT

          end

          # Support custom alignment on mobile devices
          mix_mobile_text_align td, opt, ctx

          rowspan = opt[:rowspan].to_i
          td[:rowspan] = rowspan if rowspan > 0

          mix_font td, opt, ctx, table_opt

          # In Fluid-Drop, the font-size is set to zero to overcome Outlook rendering
          # problems so it is important to warn the designer that they need to set
          # it back to a reasonable size on the TD element.
          # TODO [JDH 11/14/2015] Decide if the warning re: font-size should ever
          # be restored based on whether or not users are finding it confusing.

          if mobile.blank?

            # If the cell doesn't define it's own responsive behavior, check to
            # see if it inherits from its parent table.  DROP and SWITCH declared
            # at the table-level descend to their tds.
            pm = table_opt[:mobile]
            mobile = pm if pm == DROP || pm == SWITCH

          end

          mix_responsive td, opt, ctx, mobile

          html << td.to_s

        end

        html
      end

      private


      CLOSE_TD = '/td'
      LEFT = 'left'

      # Boolean attribute triggering automatic outlook background
      # integration in the TD.
      OUTLOOK_BG = :'outlook-bg'

    end
  end
end
