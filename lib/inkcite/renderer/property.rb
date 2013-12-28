module Inkcite
  class Renderer::Property < Renderer::Base

    def render tag, opt, ctx

      html = ctx[tag]
      if html.nil?
        ctx.error 'Unknown tag or property', { :tag => tag, :opt => opt.to_query }
        return nil
      end

      # Need to clone the property - otherwise, we modify the original property.
      # Which is bad.
      html = html.clone

      Parser.each html, VARIABLE_REGEX do |pair|

        # Split the declaration on the equals sign.
        variable, default = pair.split(EQUALS, 2)

        # Check to see if the variable has been defined in the parameters.  If so, use that
        # value - otherwise, inherit the default.
        (opt[variable.to_sym] || default).to_s

      end
    end

    private

    VARIABLE_REGEX = /\$([^\$]+)\$/

    DOLLAR = '$'
    EQUALS = '='

  end
end
