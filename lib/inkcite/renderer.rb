require_relative 'renderer/base'
require_relative 'renderer/responsive'
require_relative 'renderer/container_base'
require_relative 'renderer/special_effect'
require_relative 'renderer/image_base'
require_relative 'renderer/table_base'

require_relative 'renderer/background'
require_relative 'renderer/button'
require_relative 'renderer/carousel'
require_relative 'renderer/div'
require_relative 'renderer/fireworks'
require_relative 'renderer/footnote'
require_relative 'renderer/google_analytics'
require_relative 'renderer/image'
require_relative 'renderer/in_browser'
require_relative 'renderer/increment'
require_relative 'renderer/like'
require_relative 'renderer/link'
require_relative 'renderer/litmus_analytics'
require_relative 'renderer/lorem'
require_relative 'renderer/mobile_image'
require_relative 'renderer/mobile_only'
require_relative 'renderer/mobile_style'
require_relative 'renderer/mobile_toggle'
require_relative 'renderer/partial'
require_relative 'renderer/preheader'
require_relative 'renderer/property'
require_relative 'renderer/redacted'
require_relative 'renderer/snow'
require_relative 'renderer/social'
require_relative 'renderer/span'
require_relative 'renderer/sparkle'
require_relative 'renderer/sup'
require_relative 'renderer/table'
require_relative 'renderer/td'
require_relative 'renderer/topic'
require_relative 'renderer/trademark'
require_relative 'renderer/video_preview'

module Inkcite
  module Renderer

    def self.fix_illegal_characters value, context

      # These special characters cause rendering problems in a variety
      # of email clients.  Convert them to the correct unicode characters.
      # https://www.campaignmonitor.com/blog/post/1810/why-are-all-my-apostrophes-mis

      if context.text?
        value.gsub!(/[–—]/, '-')
        value.gsub!(/™/, '(tm)')
        value.gsub!(/®/, '(r)')
        value.gsub!(/[‘’`]/, "'")
        value.gsub!(/[“”]/, '"')
        value.gsub!(/…/, '...')

      else
        value.gsub!(/–/, '&ndash;')
        value.gsub!(/—/, '&mdash;')
        value.gsub!(/™/, '&trade;')
        value.gsub!(/®/, '&reg;')
        value.gsub!(/[‘’`]/, '&#8217;')
        value.gsub!(/“/, '&#8220;')
        value.gsub!(/”/, '&#8221;')
        value.gsub!(/é/, '&eacute;')
        value.gsub!(/…/, '&#8230;')

      end

      # Remove unicode line break characters
      value.gsub!(/\u2028/, '')

      value
    end

    def self.hex color

      # Convert #rgb into #rrggbb
      if !color.blank? && color.length == 4 && color.start_with?('#')
        red = color[1]
        green = color[2]
        blue = color[3]
        color = "##{red}#{red}#{green}#{green}#{blue}#{blue}"
      end

      color
    end

    # Joins the key-value-pairs of the provided hash into a readable
    # string destined for HTML or CSS style declarations.  For example,
    # { :bgcolor => '"#fff"' } would become bgcolor="#fff" using the
    # default equality and space delimiters.
    def self.join_hash hash, equal=EQUAL, sep=SPACE

      pairs = []

      hash.keys.sort.each do |att|
        val = hash[att]
        next if val.blank?

        # First add the attribute name - e.g. "padding" or "bgcolor"
        pair = "#{att}"

        # Only append the value if the attribute value is a non-boolean.
        # e.g. support boolean attributes via booleans ":nowrap => true"
        pair << "#{equal}#{val}" unless val == true

        pairs << pair
      end

      pairs.join(sep)
    end

    # Applies a "px" extension to unlabeled integer values.  If a labeled
    # value is detected (e.g. 2em) or a non-integer value is provided
    # (e.g. "normal") then the value is returned directly.
    def self.px val

      # Quick abort if a non-integer value has been provided.  This catches
      # cases like 3em and normal.  When provided, the value is not converted
      # to pixels and instead is returned directly.
      return val if val && val.to_i.to_s != val.to_s

      val = val.to_i
      val = "#{val}px" unless val == 0
      val
    end

    def self.quote val
      %Q("#{val}")
    end

    def self.render str, context

      Parser.each(str) do |tag|

        # Record to the context the most recent tag being processed in case
        # there are errors associated with it.
        context.last_rendered_markup = tag

        # Split the string into the tag and it's attributes.
        name, opts = tag.split(SPACE, 2)

        # Convert the options string (e.g. color=#ff9900 border=none) into parameters.
        opts = Parser.parameters(opts)

        # Strip off the leading slash (/) if there is one.  Renderers are
        open_tag = (name.starts_with?(SLASH) ? name[1..-1] : name).to_sym

        # Choose a renderer either from the dynamic set or use the default one that
        # simply renders from the property values.
        renderer = renderers[open_tag] || default_renderer

        renderer.render name, opts, context

      end

    end

    def self.render_styles styles
      join_hash(styles, COLON, SEMI_COLON)
    end

    private

    COLON      = ':'
    EQUAL      = '='
    SEMI_COLON = ';'
    SPACE      = ' '
    SLASH      = '/'

    def self.default_renderer
      @default_renderer ||= Property.new
    end

    def self.renderers

      # Dynamic renderers for custom behavior and tags.
      @renderers ||= {
          :'++'               => Increment.new,
          :a                  => Link.new,
          :background         => Background.new,
          :button             => Button.new,
          :carousel           => Carousel.new,
          :'carousel-img'     => Carousel::Image.new,
          :div                => Div.new,
          :facebook           => Social::Facebook.new,
          :fireworks          => Fireworks.new,
          :footnote           => Footnote.new,
          :footnotes          => Footnotes.new,
          :google             => GoogleAnalytics.new,
          :img                => Image.new,
          :'in-browser'       => InBrowser.new,
          :include            => Partial.new,
          :instagram          => Social::Instagram.new,
          :like               => Like.new,
          :litmus             => LitmusAnalytics.new,
          :lorem              => Lorem.new,
          :'mobile-img'       => MobileImage.new,
          :'mobile-only'      => MobileOnly.new,
          :'mobile-style'     => MobileStyle.new,
          :'mobile-toggle-on' => MobileToggleOn.new,
          :pintrest           => Social::Pintrest.new,
          :preheader          => Preheader.new,
          :r                  => Trademark.new('&reg;'),
          :redacted           => Redacted.new,
          :snow               => Snow.new,
          :span               => Span.new,
          :sparkle            => Sparkle.new,
          :sup                => Sup.new,
          :table              => Table.new,
          :td                 => Td.new,
          :tm                 => Trademark.new('&trade;'),
          :'topic'            => Topic.new,
          :'topic-list'       => TopicList.new,
          :twitter            => Social::Twitter.new,
          :'video-preview'    => VideoPreview.new
      }

    end

  end
end
