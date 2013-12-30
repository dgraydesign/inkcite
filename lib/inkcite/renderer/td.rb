module Inkcite
  module Renderer
    class Td < TableBase

      def render tag, opt, ctx

        if tag != CLOSE_TD

          att = {}
          sty = {}

          # Grab the attributes of the parent table so that the TD can inherit
          # specific values like padding, valign, responsiveness, etc.
          parent = ctx.tag_stack(:table).opts

          # Inherit base cell attributes - border, background color and image, etc.
          mix_all opt, att, sty, ctx

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

          sty[FONT_FAMILY] = font_family if !font_family.blank? && font_family != NONE

          font_size = opt[FONT_SIZE]
          unless font.blank?
            font_size ||= parent[FONT_SIZE]
            font_size ||= (ctx["#{font}-font-size"] || ctx[FONT_SIZE])
          end
          sty[FONT_SIZE] = px(font_size) unless font_size.blank?

          color = opt[:color]
          unless font.blank?
            color ||= parent[:color]
            color ||= (ctx["#{font}-color"] || ctx[TEXT_COLOR]) unless font.blank?
          end
          sty[:color] = hex(color) if !color.blank? && color != NONE

          line_height = opt[LINE_HEIGHT] || parent[LINE_HEIGHT]
          line_height ||= (ctx["#{font}-line-height"] || ctx[LINE_HEIGHT]) unless font.blank?
          sty[LINE_HEIGHT] = px(line_height) if !line_height.blank? && line_height != NONE

          font_weight = opt[FONT_WEIGHT]
          unless font.blank?
            font_weight ||= parent[FONT_WEIGHT]
            font_weight ||= ctx["#{font}-font-weight"]
          end
          sty[FONT_WEIGHT] = font_weight unless font_weight.blank?

          # Check to see if padding was declared on the parent table.  If so, inherit
          # it on all cells of the table.
          padding = (opt[:padding] || parent[:padding]).to_i
          sty[:padding] = px(padding) if padding > 0

          align = opt[:align]
          unless align.blank?
            att[:align] = align

            # Must use style to reinforce left-align text in certain email clients.
            # All other alignments are accepted naturally.
            sty[TEXT_ALIGN] = align if align == LEFT

          end

          valign = opt[:valign] || parent[:valign]
          att[:valign] = valign unless valign.blank?

          rowspan = opt[:rowspan].to_i
          att[:rowspan] = rowspan if rowspan > 0

          # Text shadowing
          mix_text_shadow opt, sty, ctx

          mobile = responsive_mode(opt)

          # If the cell doesn't define it's own responsive behavior, check to
          # see if the parent table was declared DROP.  If so, this cell needs
          # to inherit specific behavior.
          mobile = DROP if mobile.nil? && responsive_mode(parent) == DROP
          if mobile == DROP

            att[:class] = DROP

            # Briant Graves' Column Drop Pattern
            # http://briangraves.github.io/ResponsiveEmailPatterns/
            # Table goes to 100% width, cells within stack.
            ctx.responsive_styles << css_rule(tag, DROP, 'display: block; width: 100% !important; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box;')

          elsif mobile
            mix_responsive tag, mobile, att, ctx

          end

          #outlook-bg	<!-&#45;&#91;if gte mso 9]>[n]<v:rect style="width:%width%px;height:%height%px;" strokecolor="none"><v:fill type="tile" src="%src%" /></v:fill></v:rect><v:shape id="theText[rnd]" style="position:absolute;width:%width%px;height:%height%px;margin:0;padding:0;%style%">[n]<!&#91;endif]&#45;->
          #/outlook-bg	<!-&#45;&#91;if gte mso 9]></v:shape><!&#91;endif]&#45;->

        end

        render_tag(tag, att, sty)
      end

      private

      CLOSE_TD = '/td'
      LEFT = 'left'

      # Property which controls the color of text
      TEXT_COLOR = :'#text'

    end
  end
end
