require 'litmus'
require 'inkcite/mailer'

module Inkcite
  module Cli
    class Test

      def self.invoke email, opts

        # Check to see if the test-address has been specified.
        send_to = email.config[TEST_ADDRESS]
        if send_to.blank?

          # Deprecated check for the test address buried in the Litmus section.
          litmus_config = email.config[:litmus]
          send_to = litmus_config[TEST_ADDRESS] unless litmus_config.blank?

        end

        if send_to.blank?
          abort <<-USAGE.strip_heredoc

            Oops! Inkcite can't start a compatibility test because of a missing
            configuration value. In config.yml, please add or uncomment this line
            and insert your Litmus or Email on Acid static testing email address:

              test-address: '(your.static.address@testingservice.com)'

          USAGE
        end

        # Unless disabled, push the browser preview up to the server to ensure
        # that the latest images are available.
        email.upload unless opts[:'no-upload']

        Inkcite::Mailer.send(email, opts.merge({ :to => send_to }))

        true
      end

      private

      # Name of the config property that
      TEST_ADDRESS = :'test-address'

    end
  end
end
