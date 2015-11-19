require 'mail'
require 'mailgun'

module Inkcite
  class Mailer

    def self.client email

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

      self.send(email, {
              :to => to,
              :cc => cc,
              :bcc => true,
              :tag => "Preview ##{count}"
          })

    end

    def self.developer email

      count = increment(email, :developer)

      self.send(email, {
              :tag => "Developer Test ##{count}"
          })

    end

    def self.test_service email, version, test_address
      self.send_version(email, version, { :to => test_address })
    end

    def self.internal email

      recipients = email.config[:recipients]

      # Determine which preview this is
      count = increment(email, :internal)

      self.send(email, {
              :to => recipients[:internal],
              :bcc => true,
              :tag => "Internal Proof ##{count}"
          })

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

    # Sends each version of the provided email with the indicated options.
    def self.send email, opt

      email.versions.each do |version|
        self.send_version(email, version, opt)
      end

    end

    def self.send_version email, version, opt

      # The version of the email we will be sending.
      view = email.view(:preview, :email, version)

      # Subject line tag such as "Preview #3"
      tag = opt[:tag]

      subject = view.subject
      subject = "#{subject} (#{tag})" unless tag.blank?

      if config = email.config[:mailgun]
        send_version_via_mailgun config, view, subject, opt
      elsif config = email.config[:smtp]
        send_version_via_smtp config, view, subject, opt
      else
        puts 'Unable to send previews. Please configure mailgun or smtp sections in config.yml'
      end

    end

    private

    def self.send_version_via_mailgun config, view, subject, opt

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

    def self.send_version_via_smtp config, view, _subject, opt

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
      _bcc = opt[:bcc] == true

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

