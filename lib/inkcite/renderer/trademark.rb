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

        if id.blank?
          ctx.error('Missing id on trademark/registered symbol')
          id = "tm#{ctx.unique_id(:trademark)}"
        end

        ctx.once?("#{id}-trademark") ? "{sup}#{@sym}{/sup}" : ''
      end

    end
  end
end
