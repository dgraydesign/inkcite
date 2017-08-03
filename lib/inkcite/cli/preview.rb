require 'inkcite/mailer'

module Inkcite
  module Cli
    class Preview

      def self.invoke email, list, opt

        # Push the browser preview(s) up to the server to ensure that the
        # latest images and "view in browser" versions are available.
        email.upload unless opt[:'no-upload']

        # Ensure we're dealing with a symbol rather than string.
        list = list.to_sym

        preview_opt = {}

        case list
          when :client
            preview_opt[:tag] = 'Preview'
            preview_opt[:bcc] = true
          when :internal
            preview_opt[:tag] = 'Internal Preview'
            preview_opt[:bcc] = true
          when :developer
            preview_opt[:tag] = 'Developer Test'
          else
            abort <<-USAGE.strip_heredoc

              Oops!  Inkcite doesn't recognize that distribution list.  It needs
              to be one of 'client', 'internal' or 'developer':

                inkcite preview internal

            USAGE

            return
        end

        Mailer.send_to_list email, list, opt.merge(preview_opt)

      end

    end
  end
end
