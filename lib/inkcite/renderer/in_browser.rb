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

        # Cache-bust the URL to ensure recipients see the most recent version of
        # the uploaded HTML
        Util::add_query_param(url, Time.now.to_i) if !ctx.production? && ctx.is_enabled?(Email::CACHE_BUST)

        # Optional link override color.
        color = opt[:color]

        # Optional call-to-action override - otherwise defaults to view in browser.
        cta = opt[:cta] || ctx.production?? 'View&nbsp;in&nbsp;Browser' : 'Preview&nbsp;in&nbsp;Browser'

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
