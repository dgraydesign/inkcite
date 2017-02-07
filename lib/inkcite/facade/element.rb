module Inkcite
  module Renderer
    class Element

      attr_reader :mobile_style, :style, :tag

      def initialize tag, att={}

        # The tag, attribute and in-line CSS styles.
        @tag = tag
        @att = att

        # Initializing @classes to avoid a Ruby warning that it hasn't been
        # declared when it is lazy-initialized in the classes() method.
        @classes = nil

        # True if the tag self-closes as in "<img .../>"
        @self_close = att.delete(:self_close) == true

        # For caller convenience, accept a style hash from the attributes
        # or initialize it here.
        @style = att.delete(:style) || {}

        # Collection of mobile-only CSS properties for this element.
        @mobile_style = att.delete(:mobile_style) || {}

      end

      # I found myself doing a lot of Element.new('tag', { }).to_s + 'more html'
      # so this method makes it easier by allowing elements to be added to
      # strings.
      def + html
        to_s << html.to_s
      end
      alias_method :concat, :+

      def [] key
        @att[key]
      end

      def []= key, val
        @att[key] = val
      end

      def add_rule rule

        # Mark the rule as active in case it was one of the pre-defined rules
        # that can be activated on first use.
        rule.activate!

        # Add the rule to those that will affect this element
        responsive_styles << rule

        # Add the rule's klass to those that will be rendered in the
        # element's HTML.
        classes << rule.klass

        rule
      end

      def classes
        @classes ||= Set.new
      end

      def responsive_styles
        @responsive_rules ||= []
      end

      def self_close?
        @self_close
      end

      # Generates a Helper tag rather than a string tag - e.g. {img src=test.png}
      # rather than <img src=test.png>
      def to_helper
        to_s('{', '}')
      end

      def to_s open='<', close='>'

        # Convert the style hash into CSS style attribute.
        @att[:style] = Renderer.quote(Renderer.render_styles(@style)) unless @style.blank?

        # Convert the list of CSS classes assigned to this element into an attribute
        self[:class] = Renderer.quote(@classes.to_a.sort.join(' ')) unless @classes.blank?

        html = open
        html << @tag

        unless @att.empty?
          html << ' '
          html << Renderer.join_hash(@att)
        end

        html << ' /' if self_close?
        html << close

        html
      end

    end
  end
end
