require 'litmus'
require 'inkcite/mailer'

module Inkcite
  module Cli
    class Test

      def self.invoke email, opt

        # Verify that a litmus: section is defined in the config.yml
        config = email.config[:litmus]
        if !config || config.blank?
          puts "Unable to test with Litmus ('litmus:' section not found in config.yml)"
          return false
        end

        # The new Litmus launched in October, 2015 no longer uses the API for creating
        # tests and instead just accepts emails sent to the account's static email address.
        # Check to see if a test-address has been defined.
        send_to = config[:'test-address']
        if send_to.nil? || send_to.blank?
          puts "Unable to test with Litmus! ('test-address' entry missing from 'litmus:' section in the config.yml)"
          return false
        end

        # Push the browser preview up to the server to ensure that the
        # latest images are available.
        email.upload

        # Send each version to Litmus separately
        email.versions.each do |version|

          view = email.view(:preview, :email, version)

          puts "Sending '#{view.subject}' to #{send_to} ..."

          Inkcite::Mailer.litmus(email, version, send_to)

        end

        true
      end

    end
  end
end
