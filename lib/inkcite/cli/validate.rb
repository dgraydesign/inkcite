require 'nokogiri'

module Inkcite
  module Cli
    class Validate

      def self.invoke email, opts

        # True if all versions of the email are valid.
        valid = true

        # Grab the environment (e.g. production) that will be validated.
        environment = opts[:environment]

        # Check to see if a specific version is requested or if unspecified
        # all versions of the email should be validated.
        versions = Array(opts[:version] || email.versions)
        versions.each do |version|

          # The version of the email we will be sending.
          view = email.view(environment, :email, version)

          subject = view.subject

          print "Validating '#{subject}' ... "

          validator = Nokogiri::HTML(view.render!) do |config|
            config.strict
          end

          if validator.errors.any?
            puts 'Invalid!'
            validator.errors.each do |err|
              puts err.inspect
              puts err.line
            end

          else
            puts 'Valid!'

          end

          if versions.length > 1
            puts ''
          end

        end

        valid
      end

      private

      # Name of the config property that
      TEST_ADDRESS = :'test-address'

    end
  end
end


