module Inkcite
  module Renderer
    class Button < Base

      # Convenience class which makes it easy to retrieve the attributes
      # for a button.
      class Config

        def initialize ctx, opt={}
          @opt = opt
          @ctx = ctx
        end

        def bgcolor
          hex(@opt[:bgcolor] || @ctx[BUTTON_BACKGROUND_COLOR] || @ctx[Base::LINK_COLOR])
        end

        def border
          @opt[:border] || @ctx[BUTTON_BORDER]
        end

        def border_radius
          (@opt[Base::BORDER_RADIUS] || @ctx[BUTTON_BORDER_RADIUS]).to_i
        end

        def color
          hex(@opt[:color] || @ctx[BUTTON_COLOR] || Util::contrasting_text_color(bgcolor))
        end

        def float
          @opt[:align] || @opt[:float] || @ctx[BUTTON_FLOAT]
        end

        def font
          @opt[:font] || @ctx[BUTTON_FONT]
        end

        def font_weight
          @opt[Base::FONT_WEIGHT] || @ctx[BUTTON_FONT_WEIGHT]
        end

        def height
          (@opt[:height] || @ctx[BUTTON_HEIGHT]).to_i
        end

        def margin_top
          (@opt[Base::MARGIN_TOP] || @ctx[BUTTON_MARGIN_TOP]).to_i
        end

        def padding
          (@opt[:padding] || @ctx[BUTTON_PADDING]).to_i
        end

        def text_shadow
          ts = @opt[Base::TEXT_SHADOW] || @ctx[BUTTON_TEXT_SHADOW]
          unless ts
            ts = Util::brightness_value(bgcolor) > 382.5 ? Util::lighten(bgcolor, 0.25) : Util::darken(bgcolor)
          end
          hex(ts)
        end

        def width
          (@opt[:width] || @ctx[BUTTON_WIDTH]).to_i
        end

        private

        BUTTON_BACKGROUND_COLOR = :'button-background-color'
        BUTTON_BORDER = :'button-border'
        BUTTON_BORDER_RADIUS = :'button-border-radius'
        BUTTON_COLOR = :'button-color'
        BUTTON_FLOAT = :'button-float'
        BUTTON_FONT = :'button-font'
        BUTTON_FONT_WEIGHT = :'button-font-weight'
        BUTTON_HEIGHT = :'button-height'
        BUTTON_LINE_HEIGHT = :'button-line-height'
        BUTTON_MARGIN_TOP = :'button-margin-top'
        BUTTON_PADDING = :'button-padding'
        BUTTON_TEXT_SHADOW = :'button-text-shadow'
        BUTTON_WIDTH = :'button-width'

        # Convenient
        def hex color
          Renderer.hex(color)
        end

      end

      def render tag, opt, ctx

        html = ''

        if tag == 'button'

          id = opt[:id]
          href = opt[:href]

          cfg = Config.new(ctx, opt)

          # Wrap the table in a link to make the whole thing clickable.  Embed
          # a second link inside the table a graceful trick to make the
          html << "{a id=\"#{id}\" href=\"#{href}\" color=\"none\"}"
          html << "{table bgcolor=#{cfg.bgcolor}"
          html << " padding=#{cfg.padding}" if cfg.padding > 0
          html << " border=#{cfg.border}" if cfg.border
          html << " border-radius=#{cfg.border_radius}" if cfg.border_radius > 0
          html << " margin-top=#{cfg.margin_top}" if cfg.margin_top > 0
          html << " width=#{cfg.width}" if cfg.width > 0
          html << " float=#{cfg.float}" if cfg.float
          html << " mobile=\"fill\"}"
          html << "{td align=center"
          html << " height=#{cfg.height} valign=middle" if cfg.height > 0
          html << " font=\"#{cfg.font}\""
          html << " font-weight=\"#{cfg.font_weight}\"" unless cfg.font_weight.blank?
          html << " shadow=\"#{cfg.text_shadow}\" shadow-offset=-1}"
          html << "{a id=\"#{id}\" href=\"#{href}\" color=\"#{cfg.color}\"}"

        else

          html << "{/a}"
          html << "{/td}\n"
          html << "{/table}{/a}"

        end

        html
      end

    end
  end
end
