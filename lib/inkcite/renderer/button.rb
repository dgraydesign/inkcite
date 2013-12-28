module Inkcite
  class Renderer::Button < Renderer::Base

    def render tag, opt, ctx

      html = ''

      if tag == 'button'

        float   = opt[:align] || opt[:float] || ctx[BUTTON_FLOAT]
        width   = (opt[:width] || ctx[BUTTON_WIDTH]).to_i
        height  = (opt[:height] || ctx[BUTTON_HEIGHT]).to_i
        padding = (opt[:padding] || ctx[BUTTON_PADDING]).to_i
        border  = (opt[:border] || ctx[BUTTON_BORDER])
        radius  = (opt[BORDER_RADIUS] || ctx[BUTTON_BORDER_RADIUS]).to_i
        bgcolor = hex(opt[:bgcolor] || ctx[BUTTON_BACKGROUND_COLOR])

        font        = opt[:font] || ctx[BUTTON_FONT]
        color       = hex(opt[:color] || ctx[BUTTON_COLOR])
        text_shadow = hex(opt[TEXT_SHADOW] || ctx[BUTTON_TEXT_SHADOW])
        line_height = (opt[LINE_HEIGHT] || ctx[BUTTON_LINE_HEIGHT]).to_i

        id = opt[:id]
        href = opt[:href]

        # Wrap the table in a link to make the whole thing clickable.  Embed
        # a second link inside the table a graceful trick to make the
        html << "{a id=\"#{id}\" href=\"#{href}\" color=\"none\"}"
        html << "{table bgcolor=#{bgcolor}"
        html << " padding=#{padding}" if padding > 0
        html << " border=#{border}" if border
        html << " border-radius=#{radius}" if radius > 0
        html << " width=#{width}" if width > 0
        html << " float=#{float}" if float
        html << " mobile=\"fill\"}"
        html << "{td align=center"
        html << " height=#{height} valign=middle" if height > 0
        html << " font=\"#{font}\""
        html << " shadow=\"#{text_shadow}\" shadow-offset=-1}"
        html << "{a id=\"#{id}\" href=\"#{href}\" color=\"#{color}\"}"

      else

        html << "{/a}"
        html << "{/td}\n"
        html << "{/table}{/a}"

      end

      html
    end

    private

    BUTTON_BACKGROUND_COLOR = :'button-background-color'
    BUTTON_BORDER           = :'button-border'
    BUTTON_BORDER_RADIUS    = :'button-border-radius'
    BUTTON_COLOR            = :'button-color'
    BUTTON_FLOAT            = :'button-float'
    BUTTON_FONT             = :'button-font'
    BUTTON_HEIGHT           = :'button-height'
    BUTTON_LINE_HEIGHT      = :'button-line-height'
    BUTTON_PADDING          = :'button-padding'
    BUTTON_TEXT_SHADOW      = :'button-text-shadow'
    BUTTON_WIDTH            = :'button-width'

  end
end
