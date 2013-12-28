module Inkcite
  module Responsive

    # Constants
    BUTTON  = 'button'
    DROP    = 'drop'
    FILL    = 'fill'
    HIDE    = 'hide'
    SWAP    = 'swap'

    # Attribute names
    ON_MOBILE = :'on-mobile'

    def css_rule tag, klass, declarations, selector=nil

      rule = ""
      rule << tag
      rule << "[class=\"#{klass}\"]"
      rule << " #{selector}" unless selector.blank?
      rule << " { "
      rule << (declarations.is_a?(Array) ? declarations.join(' ') : declarations.to_s)
      rule << " }"

      rule
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
      ctx.error "Invalid responsive mode for {#{tag}}", { ON_MOBILE => mode }
    end

    def matches? att, mode
      mode.include?(att.to_s.downcase)
    end

    def responsive_mode opt

      att = opt[ON_MOBILE] || opt[:mobile]
      if drop?(att)
        DROP
      elsif fill?(att)
        FILL
      elsif hide?(att)
        HIDE
      elsif swap?(att)
        SWAP
      else
        nil
      end

    end

    def swap? att
      matches? att, SWAP_MODES
    end

    private

    # Variants, aliases for convenience.
    DROP_MODES = Set.new [ DROP, 'stack' ]
    FILL_MODES = Set.new [ FILL, 'stretch' ]
    HIDE_MODES = Set.new [ HIDE, 'hidden' ]
    SWAP_MODES = Set.new [ SWAP, 'replace' ]

  end
end
