require 'litmus'
require 'inkcite/mailer'

module Inkcite
  class Cli::Test

    def self.invoke email, opt

      # Push the browser preview up to the server to ensure that the
      # latest images are available.
      email.upload

      config = email.config[:litmus]

      # Initialize the Litmus base.
      Litmus::Base.new(config[:subdomain], config[:username], config[:password], true)

      # Send each version to Litmus separately
      email.versions.each do |version|

        view = email.view(:preview, :email, version)

        # This will hold the Litmus Test Version which provides the GUID (e.g. email)
        # to which we will send.
        test_version = nil

        # Check to see if this email already has a test ID.
        test_id = view.meta(:litmus_test_id)
        if test_id.blank? || opt[:new]

          email_test = Litmus::EmailTest.create

          # Store the litmus test ID in the email's meta data.
          view.set_meta :litmus_test_id, email_test['id']

          # Extract the email address we need to send the test to.
          test_version = email_test["test_set_versions"].first

        else

          # Create a new version of the test using the same ID as before.
          test_version = Litmus::TestVersion.create(test_id)

        end

        # Extract the email address to send the test to.
        send_to = test_version["url_or_guid"]

        puts "Sending '#{view.subject}' to #{send_to} ..."

        Inkcite::Mailer.litmus(email, version, send_to)

      end

      true
    end

  end
end
