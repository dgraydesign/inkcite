require 'mail'
require 'mailgun'

module Inkcite
  class Mailer

    def self.send_test email, test_address, opts

      # Determine the number of times we've emailed to this list
      count = get_count(email, :test, opts)

      # Check to see if a specific version is requested or if unspecified
      # all versions of the email should be sent.
      versions = get_versions(email, opts)

      # Will hold the instance of the Mailer::Base that will handle the
      # actual sending of the email.
      mailer_base = get_mailer_base(email)

      versions.each do |version|

        # The version of the email we will be sending.
        view = email.view(:preview, :email, version)

        subject = "#{view.subject} (Test ##{count})"
        print "Sending '#{subject}' ... "

        mailer_base.send!({ :to => test_address }, subject, view.render!)

        puts 'Sent!'

      end

      # Increment the count now that we've successfully emailed this list
      increment email, :test

    end

    def self.send_to_list email, list, opts

      # Determine the number of times we've emailed to this list
      count = get_count(email, list, opts)

      # Check to see if a specific version is requested or if unspecified
      # all versions of the email should be sent.
      versions = get_versions(email, opts)

      # Will hold the instance of the Mailer::Base that will handle the
      # actual sending of the email.
      mailer_base = get_mailer_base(email)

      # Get the email address from which the previews will be sent.
      from = mailer_base.get_from_address

      versions.each do |version|

        # The version of the email we will be sending.
        view = email.view(:preview, :email, version)

        # Subject line tag such as "Preview #3"
        tag = "#{opts[:tag]} ##{count}"

        subject = view.subject
        subject = "#{subject} (#{tag})" unless tag.blank?

        # Get the list of recipients for this version
        recipients = get_recipients(list, view, count, from)

        # Get the total number of recipients for this version
        total_recipients = recipients.inject(0) { |total, (k, v)| total + v.length }

        print "Sending '#{subject}' to #{total_recipients} recipient#{'s' if total_recipients > 1} ... "

        mailer_base.send! recipients, subject, view.render!

        puts 'Sent!'

      end

      # Increment the count now that we've successfully emailed this list
      increment email, list

    end

    private

    # Name of the distribution list used on the first preview.  For one
    # client, they wanted the first preview sent to additional people
    # but subsequent previews went to a shorter list.
    FIRST_PREVIEW = :'first-preview'

    def self.comma_set_includes? _set, value
      _set.blank? || _set.split(',').collect(&:to_sym).include?(value.to_sym)
    end

    def self.get_count email, sym, opts
      opts[:count] || email.meta(sym).to_i + 1
    end

    def self.get_mailer_base email
      mailer_base = nil

      # Check to see if
      if config = email.config[:mailgun]
        mailer_base = MailgunMailer.new(config)
      elsif config = email.config[:smtp]
        mailer_base = SmtpMailer.new(config)
      else
        abort <<-USAGE.strip_heredoc

                Oops! Inkcite can't send this email because of a configuration problem.
                Please update the mailgun or smtp sections of your config.yml file.

                  smtp:
                    host: 'smtp.gmail.com'
                    port: 587
                    domain: 'yourdomain.com'
                    username: ''
                    password: ''
                    from: 'Your Name <email@domain.com>'

                Or send via Mailgun:

                  mailgun:
                    api-key: 'key-your-api-key'
                    domain: 'mg.sending-domain.com'
                    from: 'Your Name <email@domain.com>'

        USAGE
      end

      mailer_base
    end

    def self.get_recipients list, view, count, from

      recipients = { :to => [], :cc => [], :bcc => [] }

      # Developer list always only sends to the original from address.
      if list == :developer
        recipients[:to] << from

      else

        # Always bcc the developer of the email
        recipients[:bcc] << from

        # Check to see if there is a TSV file which allows for maximum
        # configurability of the recipient list.
        recipients_file = view.email.project_file('recipients.tsv')
        if File.exist?(recipients_file)

          # Iterate through the recipients file and determine which entries match the
          # list, version and preview count...
          Util.each_line(recipients_file, false) do |line|

            # Skip comments
            next if line.start_with?('#')

            name, email, _list, delivery, min_preview, max_preview, versions = line.split("\t")
            next if name.blank? || email.blank?

            # Skip this recipient unless the distribution list matches the one
            # we're looking for.
            next unless _list.to_sym == list

            # Skip this recipient unless we've reached the minimum number of
            # earlier previews for this recipient - e.g. they only receive the
            # 2nd previews and beyond
            min_preview = min_preview.to_i
            next if min_preview > 0 && count < min_preview

            # Skip this recipient if we've already delivered the maximum number
            # of previews they should receive - e.g. they only receive the
            # first preview, no additional previews.
            max_preview = max_preview.to_i
            next if max_preview > 0 && count > max_preview

            # Skip this recipient unless
            next unless comma_set_includes?(versions, view.version)

            delivery = delivery.blank? ? :to : delivery.to_sym
            recipient = "#{name} <#{email}>"
            recipients[delivery] << recipient

          end

        else

          # Grab the array of recipients from the config.yml
          recipient_yml = view[:recipients]

          case list
            when :client
              recipients[:to] << (recipient_yml[FIRST_PREVIEW] if count == 1) || recipient_yml[:clients] || recipient_yml[:client]
              recipients[:cc] << recipient_yml[:internal]
            when :internal
              recipients[:to] = recipient_yml[:internal]
            when :developer
              recipients[:to] = from
          end

        end

      end

      return recipients
    end

    def self.get_versions email, opts
      Array(opts[:version] || email.versions)
    end

    def self.increment email, sym
      email.set_meta sym, get_count(email, sym)
    end

    # Abstract base class for the workhorses of the Mailer class.
    # Instantiated based on the config.yml settings.
    class Base

      attr_accessor :config

      def initialize config
        @config = config
      end

      def get_from_address
        @config[:from]
      end

      def send! recipients, subject, content
        raise NotImplementedError
      end
    end

    class MailgunMailer < Base
      def initialize config
        super(config)
      end

      def send! recipients, subject, content

        # First, instantiate the Mailgun Client with your API key
        mg_client = Mailgun::Client.new config[:'api-key']

        # Define your message parameters
        message_params = {
            :from => get_from_address,
            :to => recipients[:to],
            :subject => subject,
            :html => content
        }

        message_params[:cc] = recipients[:cc] unless recipients[:cc].blank?
        message_params[:bcc] = recipients[:bcc] unless recipients[:bcc].blank?

        # Send your message through the client
        mg_client.send_message config[:domain], message_params

      end
    end

    class SmtpMailer < Base
      def initialize config
        super(config)
      end

      def send! recipients, subject, content

        _config = config

        Mail.defaults do
          delivery_method :smtp, {
                  :address => _config[:host],
                  :port => _config[:port],
                  :user_name => _config[:username],
                  :password => _config[:password],
                  :authentication => :plain,
                  :enable_starttls_auto => true
              }
        end

        mail = Mail.new do
          html_part do
            content_type 'text/html; charset=UTF-8'
            body content
          end
        end

        mail[:to] = recipients[:to]
        mail[:cc] = recipients[:cc]
        mail[:bcc] = recipients[:bcc]
        mail[:from] = get_from_address
        mail[:subject] = subject

        mail.deliver!

      end
    end

  end
end


