module Inkcite
  module Renderer
    class Element

      attr_reader :tag
      attr_reader :classes

      def initialize tag, att={}

        # The tag, attribute and in-line CSS styles.
        @tag = tag
        @att = att
        @sty = {}

        # True if the tag self-closes as in "<img .../>"
        @self_close = att.delete(:self_close) == true

        # The CSS classes assigned to the element
        @classes = []

      end

      def [] key
        @att[key]
      end

      def []= key, val
        @att[key] = val
      end

      def self_close?
        @self_close
      end

      def style
        @sty
      end

      def to_s

        # Convert the style hash into CSS style attribute.
        @att[:style] = Renderer.quote(Renderer.render_styles(@sty)) unless @sty.empty?

        # Convert the list of CSS classes assigned to this element into an attribute
        self[:class] = Renderer.quote(@classes.join(' ')) unless @classes.empty?

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
