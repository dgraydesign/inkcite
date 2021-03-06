module Inkcite
  module Renderer
    class Base

      # Constants for style and property names with dashes in them.
      BACKGROUND_COLOR = :'background-color'
      BACKGROUND_GRADIENT = :'background-gradient'
      BACKGROUND_IMAGE = :'background-image'
      BACKGROUND_REPEAT = :'background-repeat'
      BACKGROUND_POSITION = :'background-position'
      BACKGROUND_SIZE = :'background-size'
      BORDER_BOTTOM = :'border-bottom'
      BORDER_COLLAPSE = :'border-collapse'
      BORDER_COLOR = :'border-color'
      BORDER_LEFT = :'border-left'
      BORDER_RADIUS = :'border-radius'
      BORDER_RIGHT = :'border-right'
      BORDER_SPACING = :'border-spacing'
      BORDER_TOP = :'border-top'
      BOX_SHADOW = :'box-shadow'
      FONT_FAMILY = :'font-family'
      FONT_SIZE = :'font-size'
      FONT_WEIGHT = :'font-weight'
      LETTER_SPACING = :'letter-spacing'
      LINE_HEIGHT = :'line-height'
      LINK_COLOR = :'#link'
      MARGIN = :'margin'
      MARGIN_BOTTOM = :'margin-bottom'
      MARGIN_LEFT = :'margin-left'
      MARGIN_RIGHT = :'margin-right'
      MARGIN_TOP = :'margin-top'
      MAX_HEIGHT = :'max-height'
      MAX_WIDTH = :'max-width'
      PADDING_X = :'padding-x'
      PADDING_Y = :'padding-y'
      TEXT_ALIGN = :'text-align'
      TEXT_DECORATION = :'text-decoration'
      TEXT_SHADOW = :'text-shadow'
      TEXT_SHADOW_BLUR = :'shadow-blur'
      TEXT_SHADOW_OFFSET = :'shadow-offset'
      VERTICAL_ALIGN = :'vertical-align'
      WEBKIT_ANIMATION = :'-webkit-animation'
      WHITE_SPACE = :'white-space'

      # Name of the property that allows an outlook-specific src to be specified
      # for an image.
      OUTLOOK_SRC = :'outlook-src'

      # CSS direction suffixes including nil/empty for convenience.
      DIRECTIONS = [ nil, :top, :right, :bottom, :left]

      # Attribute and CSS dimensions
      DIMENSIONS = [:width, :height]

      # Common value declarations
      POUND_SIGN = '#'
      NONE = 'none'

      # Zero-width space character
      ZERO_WIDTH_SPACE = '&#8203;'

      # Zero-width non-breaking character
      ZERO_WIDTH_NON_BREAKING_SPACE = '&#xfeff;'

      def render tag, opt, ctx
        raise "Not implemented: #{tag} #{opts}"
      end

      protected

      # Convenience proxy
      def detect *opts
        Util.detect(*opts)
      end

      def detect_font att, font, opt, parent, ctx
        val = detect(opt[att], ctx["#{font}-#{att}"], parent ? parent[att] : nil)

        # Sometimes font values reference other defined values so we need
        # to run them through the renderer to resolve them.
        val = Inkcite::Renderer.render(val, ctx)

        # Convience
        val = nil if none?(val)

        val
      end

      def detect_bgcolor opt, default=nil
        bgcolor = detect(opt[:bgcolor], opt[BACKGROUND_COLOR], default)
        none?(bgcolor) ? nil : hex(bgcolor)
      end

      def detect_bggradient opt, default=nil
        bggradient = detect(opt[:gradient], opt[:bggradient], opt[BACKGROUND_GRADIENT])
        none?(bggradient) ? nil : hex(bggradient)
      end

      # Convenience pass-thru to Renderer's static helper method.
      def hex color
        Renderer.hex(color)
      end

      def if_mso html
        %Q({outlook-only}#{html.to_s}{/outlook-only})
      end

      def none? val
        val.blank? || val == NONE
      end

      def mix_animation element, opt, ctx

        animation = opt[:animation]
        unless none?(animation)
          element.style[:animation] = animation
          element.style[WEBKIT_ANIMATION] = animation
        end
      end

      # Sets the element's in-line bgcolor style if it has been defined
      # in the provided options.
      def mix_background element, opt, ctx

        # Background color of the image, if populated.
        bgcolor = detect_bgcolor(opt)

        # Set the background color if the element has one.
        element.style[BACKGROUND_COLOR] = bgcolor if bgcolor

        # Automatically include background gradient support when
        # mixing in background color.
        mix_background_gradient element, opt, ctx

      end

      def mix_background_gradient element, opt, ctx

        # Background gradient support
        bggradient = detect_bggradient(opt)
        return if none?(bggradient)

        # As a shortcut a gradient can be specified simply by designating
        # both a bgcolor and the gradient color - this will insert a radial
        # gradient automatically.
        if bggradient.start_with?('#')

          # If a bgcolor is provided, the gradient goes bgcolor -> bggradient.
          # Otherwise, it goes bggradient->darker(bggradient)
          bgcolor = detect_bgcolor(opt)
          center_color = bgcolor ? bgcolor : bggradient
          outer_color = bgcolor ? bggradient : Util.darken(bggradient)

          bggradient = %Q(radial-gradient(circle at center, #{center_color}, #{outer_color}))
        end

        element.style[BACKGROUND_IMAGE] = bggradient

      end

      def mix_border element, opt, ctx
        mix_directional element, element.style, opt, ctx, :border
      end

      def mix_border_radius element, opt, ctx

        border_radius = opt[BORDER_RADIUS].to_i
        element.style[BORDER_RADIUS] = px(border_radius) if border_radius > 0

      end

      # Helper to mix CSS properties that can be defined as either a
      # singular shorthand (e.g. border) or in one or more of the
      # compass directions (e.g. border-top, border-left).
      def mix_directional element, into, opt, ctx, opt_key, css_key=nil, as_px=false

        css_key = opt_key if css_key.nil?

        # Iterate through each of the possible directions (including blank)
        # and apply them each to the element's style hash.
        DIRECTIONS.each do |dir|
          dir_opt_key = add_directional_suffix(opt_key, dir)
          dir_css_key = add_directional_suffix(css_key, dir)
          value = opt[dir_opt_key]
          next if value.blank?

          value = px(value) if as_px
          into[dir_css_key] = value
        end

      end

      def mix_font element, opt, ctx, parent=nil

        # Always ensure we have a parent to inherit from.
        parent ||= {}

        # Check for a font in either the element's specified options or inherit a setting from
        # from the parent if provided.
        font = detect(opt[:font], parent[:font])

        # Fonts can be disabled on individual cells if the parent table
        # has set one for the entire table.
        font = nil if none?(font)

        font_family = detect_font(FONT_FAMILY, font, opt, parent, ctx)
        element.style[FONT_FAMILY] = font_family unless font_family.blank?

        font_size = detect_font(FONT_SIZE, font, opt, parent, ctx)
        element.style[FONT_SIZE] = px(font_size) unless font_size.blank?

        color = detect_font(:color, font, opt, parent, ctx)
        element.style[:color] = hex(color) unless color.blank?

        line_height = detect_font(LINE_HEIGHT, font, opt, parent, ctx)
        element.style[LINE_HEIGHT] = px(line_height) unless line_height.blank?

        font_weight = detect_font(FONT_WEIGHT, font, opt, parent, ctx)
        element.style[FONT_WEIGHT] = font_weight unless font_weight.blank?

        letter_spacing = detect_font(LETTER_SPACING, font, opt, parent, ctx)
        element.style[LETTER_SPACING] = px(letter_spacing) unless none?(letter_spacing)

        # With font support comes text shadow support.
        mix_text_shadow element, opt, ctx

        font
      end

      def mix_margins element, opt, ctx, outlookCompatible=true

        # Outlook supports Margin, not margin.
        mix_directional element, element.style, opt, ctx, :margin, outlookCompatible ? :Margin : :margin, true

      end

      # Text alignment - left, right, center.
      def mix_text_align element, opt, ctx

        align = detect(opt[:align] || opt[TEXT_ALIGN])
        element.style[TEXT_ALIGN] = align unless none?(align)

      end

      def mix_text_shadow element, opt, ctx

        shadow = detect(opt[:shadow], opt[TEXT_SHADOW])
        return if shadow.blank?

        # Allow shadows to be disabled because sometimes a child element (like an
        # image within a cell or an entire cell within a table) wants to disable
        # the shadowing forced by a parent.
        if none?(shadow)
          element.style[TEXT_SHADOW] = shadow

        else

          shadow_offset = detect(opt[TEXT_SHADOW_OFFSET], ctx[TEXT_SHADOW_OFFSET], 1)
          shadow_blur = detect(opt[TEXT_SHADOW_BLUR], ctx[TEXT_SHADOW_BLUR], 0)

          element.style[TEXT_SHADOW] = "0 #{px(shadow_offset)} #{px(shadow_blur)} #{hex(shadow)}"

        end

      end

      def pct val
        "#{val}%"
      end

      def px val
        Renderer.px(val)
      end

      def quote val
        Renderer.quote(val)
      end

      def render_tag tag, attributes=nil, styles=nil

        # Convert the style hash into CSS style attribute.
        unless styles.blank?
          attributes ||= {}
          attributes[:style] = quote(Renderer.render_styles(styles))
        end

        # Check to see if this is a self-closing tag.
        self_close = attributes && attributes.delete(:self_close) == true

        html = "<#{tag}"

        unless attributes.blank?

          # Make sure multiple classes are handled properly.
          classes = attributes[:class]
          attributes[:class] = quote([*classes].join(' ')) unless classes.blank?

          html << SPACE + Renderer.join_hash(attributes)

        end

        html << '/' if self_close
        html << '>'

        html
      end

      private

      # Helper method which adds the directional suffix (e.g. top)
      # to the provided key (border) and converts to a symbol.
      def add_directional_suffix key, dir

        # Nothing to do if the direction isn't provided.
        return key if dir.blank?

        # Need to convert the key to a string since it is likely
        # a symbol that has been provided.
        dir_key = ''
        dir_key << key.to_s
        dir_key << '-'
        dir_key << dir.to_s
        dir_key.to_sym
      end

    end
  end
end
