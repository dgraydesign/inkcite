require 'uri'

module Inkcite
  class Renderer::Like < Renderer::Base

    def render tag, opt, ctx

      return '{/a}' if tag == '/like'

      # Handle the case where we're building the hosted version of the email and
      # JavaScript is used to trigger the Facebook like dialog.
      if ctx.browser?

        page = opt[:page]
        if page.blank?
          ctx.error("Like tag missing 'page' attribute")

        else

          brand = opt[:brand] || 'Us'

          # Add an externally-hosted script to the context.
          ctx.scripts << URI.parse('http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js')

          # Add the java script to be embedded.
          ctx.scripts << URI.parse('file://facebook-like.js')

          # Add the Facebook like stylesheet.
          ctx.styles << URI.parse('file://facebook-like.css')

          ctx.footer << <<-eos
            <div id="dialog-wrap">
              <div id="dialog">
                <h2>Like #{brand} on Facebook</h2>
                <div id="dialog-content" class='loading'>
                  <div class="fb-like" data-href="http://www.facebook.com/#{page}" data-send="true" data-height="100" data-width="450" data-show-faces="true"></div>
                </div>
                <div id="dialog-buttons">
                  <a href=# onclick="return closeLike();"><span>Close</span></a>
                </div>
              </div>
            </div>

            <div id="fb-root"></div>
          eos

        end

        '{a href=# onclick="return openLike();"}'

      else

        url = ctx[Inkcite::Email::VIEW_IN_BROWSER_URL]
        unless url.blank?

          # Otherwise, link to the hosted version of the email with the like hash tag
          # to trigger like automatically on arrival.
          href = Inkcite::Renderer.render(ctx[Inkcite::Email::VIEW_IN_BROWSER_URL] + '#like', ctx)

          id = opt[:id]

          "{a id=\"#{id}\" href=\"#{href}\"}"
        end

      end

    end

  end
end

