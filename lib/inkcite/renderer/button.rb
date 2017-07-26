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
          hex(@opt[:bgcolor] || @ctx[BUTTON_BGCOLOR] || @ctx[BUTTON_BACKGROUND_COLOR])
        end

        def border
          @opt[:border] || @ctx[BUTTON_BORDER]
        end

        def border_bottom
          "#{Renderer.px(bevel)} solid #{bevel_color}" if bevel > 0
        end

        def bevel
          (@opt[:bevel] || @ctx[BUTTON_BEVEL]).to_i
        end

        def bevel_color
          @opt[BEVEL_COLOR] || @ctx[BUTTON_BEVEL_COLOR]
        end

        def border_radius
          (@opt[Base::BORDER_RADIUS] || @ctx[BUTTON_BORDER_RADIUS]).to_i
        end

        def color
          hex(@opt[:color] || @ctx[BUTTON_COLOR])
        end

        def float
          @opt[:align] || @opt[:float] || @ctx[BUTTON_FLOAT]
        end

        def font
          @opt[:font] || @ctx[BUTTON_FONT]
        end

        def font_size
          (@opt[Base::FONT_SIZE] || @ctx[BUTTON_FONT_SIZE]).to_i
        end

        def font_weight
          @opt[Base::FONT_WEIGHT] || @ctx[BUTTON_FONT_WEIGHT]
        end

        def height
          (@opt[:height] || @ctx[BUTTON_HEIGHT]).to_i
        end

        def letter_spacing
          @opt[Base::LETTER_SPACING] || @ctx[BUTTON_LETTER_SPACING]
        end

        def line_height
          @opt[Base::LINE_HEIGHT] || @ctx[BUTTON_LINE_HEIGHT]
        end

        def margin_top
          (@opt[Base::MARGIN_TOP] || @ctx[BUTTON_MARGIN_TOP]).to_i
        end

        def padding
          (@opt[:padding] || @ctx[BUTTON_PADDING]).to_i
        end

        def text_shadow
          hex(@opt[Base::TEXT_SHADOW] || @ctx[BUTTON_TEXT_SHADOW])
        end

        def width
          (@opt[:width] || @ctx[BUTTON_WIDTH]).to_i
        end

        private

        BEVEL_COLOR = :'bevel-color'

        BUTTON_BACKGROUND_COLOR = :'button-background-color'
        BUTTON_BGCOLOR = :'button-bgcolor'
        BUTTON_BEVEL = :'button-bevel'
        BUTTON_BEVEL_COLOR = :'button-bevel-color'
        BUTTON_BORDER = :'button-border'
        BUTTON_BORDER_RADIUS = :'button-border-radius'
        BUTTON_COLOR = :'button-color'
        BUTTON_FLOAT = :'button-float'
        BUTTON_FONT = :'button-font'
        BUTTON_FONT_SIZE = :'button-font-size'
        BUTTON_FONT_WEIGHT = :'button-font-weight'
        BUTTON_HEIGHT = :'button-height'
        BUTTON_LETTER_SPACING = :'button-letter-spacing'
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

          # Wrap the table in a link to make the whole thing clickable.  This works
          # in most email clients but doesn't work in Outlook (for a change).
          html << "{a id=\"#{id}\" href=\"#{href}\" color=\"none\"}"

          # Responsive button is just a highly styled table/td combination with optional
          # curved corners and a lower bevel (border).
          bgcolor = cfg.bgcolor
          html << '{table'
          html << %Q( bgcolor="#{bgcolor}") unless bgcolor.blank?
          html << " padding=#{cfg.padding}" if cfg.padding > 0
          html << %Q( border="#{cfg.border}") if cfg.border
          html << " border-radius=#{cfg.border_radius}" if cfg.border_radius > 0
          html << %Q( border-bottom="#{cfg.border_bottom}") if cfg.bevel > 0

          # Need to separate borders that are collapsed by default - otherwise, the bevel
          # renders incorrectly.
          html << ' border-collapse=separate' if cfg.border || cfg.bevel > 0

          html << " margin-top=#{cfg.margin_top}" if cfg.margin_top > 0
          html << " width=#{cfg.width}" if cfg.width > 0
          html << " float=#{cfg.float}" if cfg.float
          html << %Q( mobile="fill"}\n)
          html << "{td align=center"
          html << " height=#{cfg.height} valign=middle" if cfg.height > 0
          html << %Q( font="#{cfg.font}" color="none")
          html << " line-height=#{cfg.line_height}" unless cfg.line_height.blank?
          html << %Q( font-size="#{cfg.font_size}") if cfg.font_size > 0
          html << %Q( font-weight="#{cfg.font_weight}") unless cfg.font_weight.blank?

          # Text on the button gets a shadow automatically unless the shadow
          # color matches the background color of the button.
          shadow = cfg.text_shadow
          html << %Q( shadow="#{shadow}" shadow-offset=-1) if shadow != bgcolor

          html << '}'

          # Second, internal link for Outlook users that makes the inside of the button
          # clickable.
          html << %Q({a id="#{id}" href="#{href}" color="#{cfg.color}")
          html << %Q( letter-spacing="#{cfg.letter_spacing}") unless cfg.letter_spacing.blank?
          html << %q(})


        else

          html << "{/a}{/td}\n{/table}{/a}"

        end

        html
      end

    end
  end
end
