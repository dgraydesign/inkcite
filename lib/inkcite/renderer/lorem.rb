module Inkcite
  module Renderer
    class Lorem < Base

      def render tag, opt, ctx

        # Lazy load only if Lorem is used in the email.
        require 'faker'

        type = (opt[:type] || :sentences).to_sym

        # Get the limit (e.g. the number of sentences )
        limit = opt[:sentences] || opt[:size] || opt[:limit] || opt[:count]

        # Always warn the creator that there is Lorem Ipsum in the email because
        # we don't want it to ship accidentally.
        ctx.error 'Email contains Lorem Ipsum' unless opt[:force]

        if type == :headline
          words = (limit || 4).to_i
          Faker::Lorem.words(words).join(SPACE).titlecase

        elsif type == :words
          words = (limit || 7).to_i
          Faker::Lorem.words(words).join(SPACE)

        else
          sentences = (limit || 3).to_i
          Faker::Lorem.sentences(sentences).join(SPACE)

        end

      end

      private

      SPACE = ' '

    end
  end
end
