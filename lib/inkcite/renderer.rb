require_relative 'renderer/base'
require_relative 'renderer/responsive'
require_relative 'renderer/table_base'

require_relative 'renderer/button'
require_relative 'renderer/google_analytics'
require_relative 'renderer/image'
require_relative 'renderer/in_browser'
require_relative 'renderer/like'
require_relative 'renderer/link'
require_relative 'renderer/litmus'
require_relative 'renderer/lorem'
require_relative 'renderer/mobile_image'
require_relative 'renderer/outlook_background'
require_relative 'renderer/property'
require_relative 'renderer/table'
require_relative 'renderer/td'

module Inkcite
  module Renderer

    def self.hex color

      # Convert #rgb into #rrggbb
      if !color.blank? && color.length < 7
        red = color[1]
        green = color[2]
        blue = color[3]
        color = "##{red}#{red}#{green}#{green}#{blue}#{blue}"
      end

      color
    end

    def self.render str, context

      Parser.each(str) do |tag|

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

    private

    SPACE = ' '
    SLASH = '/'

    def self.default_renderer
      @default_renderer ||= Property.new
    end

    def self.renderers

      # Dynamic renderers for custom behavior and tags.
      @renderers ||= {
          :a            => Link.new,
          :button       => Button.new,
          :google       => GoogleAnalytics.new,
          :img          => Image.new,
          :'in-browser' => InBrowser.new,
          :like         => Like.new,
          :litmus       => Litmus.new,
          :lorem        => Lorem.new,
          :'mobile-img' => MobileImage.new,
          :'outlook-bg' => OutlookBackground.new,
          :table        => Table.new,
          :td           => Td.new
      }

    end

  end
end
