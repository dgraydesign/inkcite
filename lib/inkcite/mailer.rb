require 'mail'
require 'mailgun'

module Inkcite
  class Mailer

    def self.client email, opts

      # Determine which preview this is
      count = increment(email, :preview)

      # Get the declared set of recipients.
      recipients = email.config[:recipients]

      # Get the list of client address(es) - check both client and clients
      # as a convenience.
      to = recipients[:clients] || recipients[:client]

      # If this is the first preview, check to see if there is an
      # additional set of recipients for this initial mailing.
      if count == 1
        also_to = recipients[FIRST_PREVIEW]
        #to = [* to] + [* also_to] unless also_to.blank?
        to = [* also_to] unless also_to.blank?
      end

      # Always cc internal recipients so everyone stays informed of feedback.
      cc = recipients[:internal]

      self.send(email, opts.merge({
                  :to => to,
                  :cc => cc,
                  :bcc => true,
                  :tag => "Preview ##{count}"
              }))

    end

    def self.developer email, opts

      count = increment(email, :developer)

      self.send(email, opts.merge({
                  :tag => "Developer Test ##{count}"
              }))

    end

    def self.internal email, opts

      recipients = email.config[:recipients]

      # Determine which preview this is
      count = increment(email, :internal)

      self.send(email, opts.merge({
                  :to => recipients[:internal],
                  :bcc => true,
                  :tag => "Internal Proof ##{count}"
              }))

    end

    # Sends each version of the provided email with the indicated options.
    def self.send email, opts

      # Check to see if a specific version is requested or if unspecified
      # all versions of the email should be sent.
      versions = Array(opts[:version] || email.versions)

      # Will hold the instance of the Mailer::Base that will handle the
      # actual sending of the email.
      mailer_base = nil

      # Check to see if
      if config = email.config[:mailgun]
        mailer_base = MailgunMailer.new
      elsif config = email.config[:smtp]
        mailer_base = SmtpMailer.new
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

      versions.each do |version|

        # The version of the email we will be sending.
        view = email.view(:preview, :email, version)

        # Subject line tag such as "Preview #3"
        tag = opts[:tag]

        subject = view.subject
        subject = "#{subject} (#{tag})" unless tag.blank?

        puts "Sending '#{subject}' ..."

        mailer_base.send! config, view, subject, opts

      end

    end

    private

    # Name of the distribution list used on the first preview.  For one
    # client, they wanted the first preview sent to additional people
    # but subsequent previews went to a shorter list.
    FIRST_PREVIEW = :'first-preview'

    def self.increment email, sym
      count = email.meta(sym).to_i + 1
      email.set_meta sym, count
    end

    # Abstract base class for the workhorses of the Mailer class.
    # Instantiated based on the config.yml settings.
    class Base
      def send! config, view, subject, opt
        raise NotImplementedError
      end
    end

    class MailgunMailer < Base
      def send! config, view, subject, opt

        # The address of the developer
        from = config[:from]

        # First, instantiate the Mailgun Client with your API key
        mg_client = Mailgun::Client.new config[:'api-key']

        # Define your message parameters
        message_params = {
            :from => from,
            :to => opt[:to] || from,
            :subject => subject,
            :html => view.render!
        }

        message_params[:cc] = opt[:cc] unless opt[:cc].blank?
        message_params[:bcc] = from if opt[:bcc] == true

        # Send your message through the client
        mg_client.send_message config[:domain], message_params

      end
    end

    class SmtpMailer < Base
      def send! config, view, _subject, opt

        Mail.defaults do
          delivery_method :smtp, {
                  :address => config[:host],
                  :port => config[:port],
                  :user_name => config[:username],
                  :password => config[:password],
                  :authentication => :plain,
                  :enable_starttls_auto => true
              }
        end

        # The address of the developer
        _from = config[:from]

        # True if the developer should be bcc'd.
        _bcc = !!opt[:bcc]

        mail = Mail.new do

          to opt[:to] || _from
          cc opt[:cc]
          from _from
          subject _subject

          bcc(_from) if _bcc

          html_part do
            content_type 'text/html; charset=UTF-8'
            body view.render!
          end

        end

        mail.deliver!

      end
    end

  end
end


