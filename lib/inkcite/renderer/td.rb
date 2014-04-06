module Inkcite
  module Renderer
    class Td < TableBase

      def render tag, opt, ctx

        tag_stack = ctx.tag_stack(:td)

        if tag == CLOSE_TD
          tag_stack.pop
          return '</td>'
        end

        # Push this tag onto the stack so that child elements (e.g. links)
        # can have access to its attributes.
        tag_stack << opt

        # Grab the attributes of the parent table so that the TD can inherit
        # specific values like padding, valign, responsiveness, etc.
        parent = ctx.parent_opts(:table)

        td = Element.new('td')

        # Inherit base cell attributes - border, background color and image, etc.
        mix_all td, opt, ctx

        # Force the td to collapse to a single pixel to support images that
        # are less than 15 pixels.
        opt.merge!({
            :font => NONE,
            :color => NONE,
            FONT_SIZE => 1,
            LINE_HEIGHT => 1
        }) unless opt[:flush].blank?

        # Check to see if padding was declared on the parent table.  If so, inherit
        # it on all cells of the table.
        padding = detect(opt[:padding], parent[:padding]).to_i
        td.style[:padding] = px(padding) if padding > 0

        align = opt[:align]
        unless align.blank?
          td[:align] = align

          # Must use style to reinforce left-align text in certain email clients.
          # All other alignments are accepted naturally.
          td.style[TEXT_ALIGN] = align if align == LEFT

        end

        valign = opt[:valign] || parent[:valign]
        td[:valign] = valign unless valign.blank?

        rowspan = opt[:rowspan].to_i
        td[:rowspan] = rowspan if rowspan > 0

        mix_font td, opt, ctx, ctx[FONT_FAMILY], parent

        # If the cell doesn't define it's own responsive behavior, check to
        # see if the parent table was declared DROP.  If so, this cell needs
        # to inherit specific behavior.
        mobile = opt[:mobile]
        mobile = DROP if mobile.blank? && parent[:mobile] == DROP

        mix_responsive td, opt, ctx, mobile

        #outlook-bg	<!-&#45;&#91;if gte mso 9]>[n]<v:rect style="width:%width%px;height:%height%px;" strokecolor="none"><v:fill type="tile" src="%src%" /></v:fill></v:rect><v:shape id="theText[rnd]" style="position:absolute;width:%width%px;height:%height%px;margin:0;padding:0;%style%">[n]<!&#91;endif]&#45;->
        #/outlook-bg	<!-&#45;&#91;if gte mso 9]></v:shape><!&#91;endif]&#45;->

        td.to_s
      end

      private

      CLOSE_TD = '/td'
      LEFT = 'left'

      # Property which controls the color of text
      TEXT_COLOR = :'#text'

    end
  end
end
