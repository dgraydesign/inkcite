module Inkcite
  module Renderer
    module Responsive

      # Constants
      BUTTON  = 'button'
      DROP    = 'drop'
      FILL    = 'fill'
      HIDE    = 'hide'

      def css_rule tag, klass, declarations, selector=nil

        rule = ""
        rule << tag
        rule << "[class~=#{quote(klass)}]"
        rule << " #{selector}" unless selector.blank?
        rule << " { "
        if declarations.is_a?(Hash)
          rule << Renderer.render_styles(declarations)
        elsif declarations.is_a?(Array)
          rule << declarations.join(' ')
        else
          rule << declarations.to_s
        end
        rule << " }"

        rule
      end

      def button? att
        matches? att, BUTTON_MODES
      end

      # Returns true if the attribute value corresponds to the
      # drop pattern.
      def drop? att
        matches? att, DROP_MODES
      end

      # Returns true if the attribute value corresponds to the
      # fill or stretch pattern.
      def fill? att
        matches? att, FILL_MODES
      end

      # Returns true if the attribute value corresponds to the
      # hide on mobile pattern.
      def hide? att
        matches? att, HIDE_MODES
      end

      def invalid_mode tag, mode, ctx
        ctx.error "Invalid responsive mode for {#{tag}}", { :mobile => mode }
      end

      def matches? att, mode
        mode.include?(att.to_s.downcase)
      end

      def responsive_mode opt

        att = opt[:mobile]
        if button?(att)
          BUTTON
        elsif drop?(att)
          DROP
        elsif fill?(att)
          FILL
        elsif hide?(att)
          HIDE
        else
          nil
        end

      end

      private

      # Variants, aliases for convenience.
      BUTTON_MODES  = Set.new [ BUTTON ]
      DROP_MODES    = Set.new [ DROP, 'stack' ]
      FILL_MODES    = Set.new [ FILL, 'stretch' ]
      HIDE_MODES    = Set.new [ HIDE, 'hidden' ]

    end
  end
end
