module Inkcite
  module Renderer
    class Trademark < Base

      def initialize sym
        @sym = sym
      end

      def render tag, opt, ctx

        # Check to see if there is an ID associated with this symbol.
        # If so, it only needs to appear once.
        id = opt[:id]

        id.blank? || ctx.once?("#{id}-trademark") ? "{sup}#{@sym}{/sup}" : ''
      end

    end
  end
end
