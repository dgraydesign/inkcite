module Inkcite
  module Renderer
    class Topic < Base

      class Instance

        # Name of the topic as it will appear in the topic list.
        attr_reader :name

        # Order of the topic, higher wins
        attr_reader :priority

        def initialize name, priority
          @name = name
          @priority = priority
        end

      end

      def render tag, opt, ctx

        name = opt[:name]

        if name.blank?
          ctx.error 'Every topic must have a name'

        else

          # Initialize the array of topic instances that live in the
          # View's arbitrary data holder.
          ctx.data[:topics] ||= []

          # Push a topic instance onto the list
          ctx.data[:topics] << Instance.new(name, opt[:priority].to_i)

        end

        nil
      end

    end

    class TopicList < Base

      include PostProcessor

      def post_process html, ctx

        topics = ctx.data[:topics]
        if topics.blank?
          ctx.error '{topic-list} included but no topics defined'

        else

          # Sort the topics highest priority first.
          sorted_topics = topics.sort { |lhs, rhs| rhs.priority <=> lhs.priority }.collect(&:name).join(', ')
          html.gsub!(TOC_INTERMEDIARY, sorted_topics)

        end

        html
      end

      def render tag, opt, ctx
        ctx.post_processors << self
        TOC_INTERMEDIARY
      end

      private

      TOC_INTERMEDIARY = '%%TOPIC-LIST-PLACEHOLDER%%'

    end

  end
end
