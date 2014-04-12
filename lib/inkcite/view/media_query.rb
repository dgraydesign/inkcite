module Inkcite
  class View
    class MediaQuery

      def initialize view, max_width

        @view = view
        @max_width = max_width

        # Initialize the responsive styles used in this email.  This will hold
        # an array of Responsive::Rule objects.
        @responsive_styles = Renderer::Responsive.presets(view)

      end

      def << rule

        # Rules only get added once
        @responsive_styles << rule unless @responsive_styles.include?(rule)

        rule
      end

      def active_styles
        @responsive_styles.select(&:active?)
      end

      def blank?
        @responsive_styles.none?(&:active?)
      end

      def find_by_declaration declarations
        @responsive_styles.detect { |r| r.declarations == declarations }
      end

      def find_by_klass klass
        @responsive_styles.detect { |r| r.klass == klass }
      end

      def find_by_tag_and_klass tag, klass
        @responsive_styles.detect { |r| r.klass == klass  && r.include?(tag) }
      end

      def to_a

        css = []
        css << "@media only screen and (max-width: #{Inkcite::Renderer::px(@max_width)}) {"
        css += active_styles.collect(&:to_css)
        css << "}"

        css
      end

      def to_css
        to_a.join("\n")
      end

    end
  end
end
