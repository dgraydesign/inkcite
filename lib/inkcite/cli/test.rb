require 'litmus'
require 'inkcite/mailer'

module Inkcite
  module Cli
    class Test

      def self.invoke email, opt

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

        # Push the browser preview up to the server to ensure that the
        # latest images are available.
        email.upload

        # Typically the user will only provide a single test address but here
        # we convert to an array in case the user is sending to multiple
        # addresses for their own compatibility testing.
        send_to = Array(send_to)

        # Check to see if the user wants to test a specific version of the
        # email - otherwise test all of them.
        versions = Array(opt[:version] || email.versions)

        # Send each version to the testing service separately
        versions.each do |version|

          view = email.view(:preview, :email, version)
          puts "Sending '#{view.subject}' to #{send_to.join(', ')} ..."

          Inkcite::Mailer.send_version(email, version, { :to => send_to })

        end

        true
      end

      private

      # Name of the config property that
      TEST_ADDRESS = :'test-address'

    end
  end
end
