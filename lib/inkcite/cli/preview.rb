require 'inkcite/mailer'

module Inkcite
  module Cli
    class Preview

      def self.invoke email, to, opt

        # Push the browser preview(s) up to the server to ensure that the
        # latest images and "view in browser" versions are available.
        email.upload

        case to.to_sym
          when :client
            Inkcite::Mailer.client(email, opt)
          when :internal
            Inkcite::Mailer.internal(email, opt)
          when :developer
            Inkcite::Mailer.developer(email, opt)
          else
            raise "Invalid preview distribution target"
        end

      end

    end
  end
end
