require 'mail'

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
        to = [* to] + [* also_to] unless also_to.blank?
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

    def self.litmus email, version, litmus_email
      self.send_version(email, version, { :to => litmus_email })
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

      config = email.config[:smtp]

      Mail.defaults do
        delivery_method :smtp, {
          :address              => config[:host],
          :port                 => config[:port],
          :user_name            => config[:username],
          :password             => config[:password],
          :authentication       => :plain,
          :enable_starttls_auto => true
        }
      end

      # The address of the developer
      _from = config[:from]

      # Subject line tag such as "Preview #3"
      _tag = opt[:tag]

      # True if the developer should be bcc'd.
      _bcc = opt[:bcc] == true

      # The version of the email we will be sending.
      _view = email.view(:preview, :email, version)

      _subject = _view.subject
      _subject = "#{_subject} (#{_tag})" unless _tag.blank?

      mail = Mail.new do

        to      opt[:to] || _from
        cc      opt[:cc]
        from    _from
        subject _subject

        bcc(_from) if _bcc

        html_part do
          content_type 'text/html; charset=UTF-8'
          body _view.render!
        end

      end

      mail.deliver!

    end

  end
end

