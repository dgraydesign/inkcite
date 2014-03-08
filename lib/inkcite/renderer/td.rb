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

        # Font handling is keyed off of having the "font" attribute
        font = opt[:font] || parent[:font]

        # Fonts can be disabled on individual cells if the parent table
        # has set one for the entire table.
        font = nil if font == NONE

        font_family = opt[FONT_FAMILY]
        unless font.blank?
          font_family ||= parent[FONT_FAMILY]
          font_family ||= ctx["#{font}-font-family"]

          # If we've inherited font-family from a parent, it's not necessary
          # to specify it again if it's the default font for the email.
          # Font family generally cascades.
          font_family = nil if font_family == ctx[FONT_FAMILY]

        end

        td.style[FONT_FAMILY] = font_family if !font_family.blank? && font_family != NONE

        font_size = opt[FONT_SIZE]
        unless font.blank?
          font_size ||= parent[FONT_SIZE]
          font_size ||= (ctx["#{font}-font-size"] || ctx[FONT_SIZE])
        end
        td.style[FONT_SIZE] = px(font_size) unless font_size.blank?

        color = opt[:color]
        unless font.blank?
          color ||= parent[:color]
          color ||= (ctx["#{font}-color"] || ctx[TEXT_COLOR]) unless font.blank?
        end
        td.style[:color] = hex(color) if !color.blank? && color != NONE

        line_height = opt[LINE_HEIGHT] || parent[LINE_HEIGHT]
        line_height ||= (ctx["#{font}-line-height"] || ctx[LINE_HEIGHT]) unless font.blank?
        td.style[LINE_HEIGHT] = px(line_height) if !line_height.blank? && line_height != NONE

        font_weight = opt[FONT_WEIGHT]
        unless font.blank?
          font_weight ||= parent[FONT_WEIGHT]
          font_weight ||= ctx["#{font}-font-weight"]
        end
        td.style[FONT_WEIGHT] = font_weight unless font_weight.blank?

        # Check to see if padding was declared on the parent table.  If so, inherit
        # it on all cells of the table.
        padding = (opt[:padding] || parent[:padding]).to_i
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

        # Text shadowing
        mix_text_shadow td, opt, ctx

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
