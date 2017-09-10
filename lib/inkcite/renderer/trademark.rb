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

        return '' unless ctx.once?("#{id}-trademark")

        no_sup = opt[:'no-sup']

        html = ''
        html << '{sup}' unless no_sup
        html << @sym

        # If the trademark symbol should be followed immediately with a footnote
        # render the {footnote} Helper with the once flag and the no-sup attribute
        # to ensure unnecessary superscripts don't get rendered.
        footnote = opt[:footnote]
        unless footnote.blank?
          html << %Q({footnote id="#{id}")

          # Only include the footnote text if the attribute is not boolean
          html << %Q( text="#{footnote}") if footnote != true
          html << %q( once}) unless footnote.blank?
        end

        html << '{/sup}' unless no_sup

        html
      end

    end
  end
end
