module Inkcite
  module Renderer
    class Redacted < Base

      def render tag, opt, ctx

        # Like Lorem Ipsum, warn the creator that there is redaction in
        # the email unless the warn parameter is true.
        ctx.error 'Email contains redacted content' unless opt[:force]

        # The obscuring character defaults to 'x' but can be overridden
        # using the 'with' attribute.
        with = opt[:with] || 'x'

        # Grab the text to be redacted, then apply the correct obscuring
        # character based on the case of the original letters.
        text = opt[:text]
        text.gsub!(/[A-Z]/, with.upcase)
        text.gsub!(/[a-z0-9]/, with.downcase)
        text

      end

    end

  end
end
