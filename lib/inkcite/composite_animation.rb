module Inkcite
  class Animation

    class CompositeAnimation

      def initialize
        @animations = []
      end

      def << animation
        @animations << animation
      end

      def to_keyframe_css
        @animations.collect(&:to_keyframe_css).join("\n")
      end

      def to_s

        # Render each of the animations in the collection and join them
        # in a single, comma-delimited string.
        @animations.collect(&:to_s).join(', ')

      end


    end

  end
end
