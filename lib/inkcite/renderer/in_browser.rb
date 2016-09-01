
module Inkcite
  module Renderer
    class InBrowser < Base

      def render tag, opt, ctx

        # You can only view in-browser if we're viewing an email.
        return nil unless ctx.email?

        url = ctx[Inkcite::Email::VIEW_IN_BROWSER_URL]
        return nil if url.blank?

        browser_view = ctx.email.view(ctx.environment, :browser, ctx.version)

        # Make sure we're converting any embedded values in the host URL
        url = Renderer.render(url, browser_view)

        # Optional link override color.
        color = opt[:color]

        # Optional call-to-action override - otherwise defaults to view in browser.
        cta = opt[:cta] || ctx.production?? 'View in Browser' : 'Preview in Browser'

        id = opt[:id] || 'in-browser'

        html = "{a id=\"#{id}\" href=\"#{url}\""
        html << " color=\"#{color}\"" unless color.blank?
        html << '}'
        html << cta
        html << '{/a}'

        html
      end

    end
  end
end
