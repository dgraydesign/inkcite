require 'inkcite/mailer'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'

module Inkcite
  module Cli
    class Scope

      def self.invoke email, opts

        # Push the browser preview(s) up to the server to ensure that the
        # latest images and "view in browser" versions are available.
        email.upload

        puts "Scoping your email ..."

        # Check to see if the Litmus section has been configured in the
        # config.yml file - if so, we'll use their Litmus credentials
        # so the email is associated with their account.
        config = email.config[:litmus]

        # True if the designer has a Litmus account.  We'll use their
        # username and password to authenticate the request in an effort
        # to associate it with their Litmus account.
        has_litmus = !config.blank?
        if has_litmus
          username = config[:username]
          password = config[:password]
        end

        # Litmus Scope endpoint
        uri = URI.parse('https://litmus.com/scope/api/v1/emails/')
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        # Check to see if a specific version is requested or if unspecified
        # all versions of the email should be sent.
        versions = Array(opts[:version] || email.versions)

        versions.each do |version|

          # The version of the email we will be sending.
          view = email.view(:preview, :email, version)

          subject = view.subject

          # Use Mail to assemble the SMTP-formatted content of the email
          # but don't actually send the message.  The to: and from:
          # addresses do not need to be legitimate addresses.
          mail = Mail.new do
            from '"Inkcite" <inkcite@inkceptional.com>'
            to '"Awesome Designer" <xxxxxxx@xxxxxxxxxxxx.xxx>'
            subject subject

            html_part do
              content_type 'text/html; charset=UTF-8'
              body view.render!
            end
          end

          # Send an HTTPS post to Litmus with the encoded SMTP content
          # produced by Mail.
          scope_request = Net::HTTP::Post.new(uri.path)
          scope_request.basic_auth(username, password) unless username.blank?
          scope_request.set_form_data('email[source]' => mail.to_s)

          begin

            response = https.request(scope_request)
            case response
              when Net::HTTPSuccess
                result = JSON.parse(response.body)
                slug = result['email']['slug']
                puts "'#{subject}' shared to https://litmus.com/scope/#{slug}"

              when Net::HTTPUnauthorized
                abort <<-ERROR.strip_heredoc

                          Oops! Inkcite wasn't able to scope your email because of an
                          authentication problem with Litmus.  Please check the settings
                          in config.yml:

                            litmus:
                              username: '#{username}'
                              password: '#{password}'

                ERROR

              when Net::HTTPServerError
                abort <<-ERROR.strip_heredoc

                           Oops! Inkcite wasn't able to scope your email because Litmus'
                           server returned an error.  Please try again later.

                           #{response.message}

                ERROR
              else
                raise response.message
            end

          rescue Exception => e
            abort <<-ERROR.strip_heredoc

               Oops! Inkcite wasn't able to scope your email because of an
               unexpected error.  Please try again later.

                  #{e.message}

            ERROR
          end


        end

        unless has_litmus
          puts 'Note! Your scoped email will expire in 15 days.'
        end

        true
      end

    end
  end
end
