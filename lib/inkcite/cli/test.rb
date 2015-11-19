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
          puts ''
          puts "Oops! Inkcite can't start a compatibility test because of a missing"
          puts 'configuration value. In config.yml, please uncomment or add:'
          puts ''
          puts "test-address: '(your.static.address@testingservice.com)'"
          puts ''
          puts 'Insert your static testing email address from Litmus (litmus.com) or'
          puts 'Email on Acid (emailonacid.com).'
          puts ''
          return false
        end

        # Push the browser preview up to the server to ensure that the
        # latest images are available.
        email.upload

        # Send each version to Litmus separately
        email.versions.each do |version|

          view = email.view(:preview, :email, version)

          puts "Sending '#{view.subject}' to #{send_to} ..."

          Inkcite::Mailer.test_service(email, version, send_to)

        end

        true
      end

      private

      # Name of the config property that
      TEST_ADDRESS = :'test-address'

    end
  end
end
