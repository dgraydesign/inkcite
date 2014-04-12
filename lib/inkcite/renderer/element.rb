module Inkcite
  module Renderer
    class Element

      attr_reader :tag

      def initialize tag, att={}

        # The tag, attribute and in-line CSS styles.
        @tag = tag
        @att = att

        # True if the tag self-closes as in "<img .../>"
        @self_close = att.delete(:self_close) == true

      end

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

      def style
        @styles ||= {}
      end

      def to_s

        # Convert the style hash into CSS style attribute.
        @att[:style] = Renderer.quote(Renderer.render_styles(@styles)) unless @styles.blank?

        # Convert the list of CSS classes assigned to this element into an attribute
        self[:class] = Renderer.quote(@classes.to_a.sort.join(' ')) unless @classes.blank?

        html = '<'
        html << @tag

        unless @att.empty?
          html << ' '
          html << Renderer.join_hash(@att)
        end

        html << ' /' if self_close?
        html << '>'

        html
      end

    end
  end
end
