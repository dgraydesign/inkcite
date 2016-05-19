require 'inkcite/mailer'

module Inkcite
  module Cli
    class Preview

      def self.invoke email, to, opt

        # Push the browser preview(s) up to the server to ensure that the
        # latest images and "view in browser" versions are available.
        email.upload

        also = opt[:also]
        unless also.blank?

          # Sometimes people use commas to separate the --also addresses so
          # explode those into an array for convenience. Email is already
          # hard enough.
          if also.any? { |a| a.match(',') }
            also = also.collect { |a| a.split(',') }.flatten

            # Since opt is frozen by Thor we need to make a copy of it in order
            # to inject the new array of recipients back into it.
            opt = opt.dup
            opt[:also] = also

          end
        end

        case to.to_sym
          when :client
            Inkcite::Mailer.client(email, opt)
          when :internal
            Inkcite::Mailer.internal(email, opt)
          when :developer
            Inkcite::Mailer.developer(email, opt)
          else
            abort <<-USAGE.strip_heredoc

              Oops!  Inkcite doesn't recognize that distribution list.  It needs
              to be one of 'client', 'internal' or 'developer':

                inkcite preview internal

            USAGE
        end

      end

    end
  end
end
