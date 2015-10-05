require 'litmus'

module Inkcite
  module Renderer
    class LitmusAnalytics < Base

      def render tag, opt, ctx

        # Litmus tracking is enabled only for production emails.
        return nil unless ctx.production? && ctx.email?

        # Deprecated code/id parameters.  They shouldn't be passed anymore.
        report_id = opt[:code] || opt[:id]
        merge_tag = opt[MERGE_TAG] || ctx[MERGE_TAG]

        # Initialize the Litmus API.
        config = ctx.config[:litmus]
        Litmus::Base.new(config[:subdomain], config[:username], config[:password], true)

        # Will hold the Litmus Report object from which we'll retrieve the
        # bug HTML to inject into the email.
        report = nil

        # If no code has been provided by the designer, check to see
        # if one has been previously recorded for this version.  If
        # so, use it - otherwise, require one from litmus automatically.
        if report_id.blank?

          # Check to see if a campaign has been previously created for this
          # version so the ID can be reused.
          report_id = ctx.meta(:litmus_report_id)
          if report_id.blank?

            # Create a new report object using the title of the email specified
            # in the helpers file.
            report = Litmus::Report.create(ctx.title)

            # Retrieve the unique ID assigned by Litmus and then stuff it
            # into the meta data so we don't create a new one on future
            # builds.
            report_id = report['id']
            ctx.set_meta :litmus_report_id, report_id

          end

        end

        if report.nil?

          report = Litmus::Report.show(report_id)
          if report.nil?
            ctx.error 'Invalid Litmus Analytics code or id', :code => report_id
            return nil
          end

        end

        # Grab the HTML from Litmus that needs to be injected into the source
        # of the email.
        bug_html = report[BUG_HTML]

        # Replace the merge tag, if one was provided.
        bug_html.gsub!('[UNIQUE]', merge_tag) unless merge_tag.nil?

        # Inject HTML into the footer of the email where it won't be subject
        # to inline'n or compression.
        ctx.footer << bug_html

        nil
      end

      private

      BUG_HTML  =  'bug_html'
      MERGE_TAG = :'merge-tag'

    end
  end
end
