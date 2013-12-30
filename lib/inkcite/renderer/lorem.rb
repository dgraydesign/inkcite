module Inkcite
  module Renderer
    class Lorem < Base

      def render(tag, opt, ctx)

        require 'faker'

        type = (opt[:type] || :sentences).to_sym

        # Get the limit (e.g. the number of sentences )
        limit = opt[:sentences] || opt[:size] || opt[:limit] || opt[:count]

        ctx.error 'Email contains Lorem Ipsum'

        if type == :headline

          words = (limit || 4).to_i
          Faker::Lorem.words(words).join(SPACE).titlecase

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
