module Inkcite
  module Renderer
    class GoogleAnalytics < Base

      def render tag, opt, ctx

        # Google analytics only possible in a browser version of the email.
        return nil unless ctx.browser?

        tracking_code = ctx[:code] || ctx[:id] || ctx[GOOGLE_ANALYTICS]
        return nil if tracking_code.blank?

        # Push the google analytics code onto the context's inline scripts.
        script = <<-EOS
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
          ga('create', '#{tracking_code}');
          ga('set', 'campaignName', '#{ctx.project}|#{ctx.issue.name}');
          ga('send', 'pageview');
        EOS

        ctx.scripts << script

        nil
      end

      private

      GOOGLE_ANALYTICS = :'google-analytics'

    end
  end
end
