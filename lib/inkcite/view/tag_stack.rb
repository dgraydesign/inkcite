module Inkcite
  class View
    class TagStack

      attr_reader :tag

      delegate :empty?, :length, :to => :opts

      def initialize tag, ctx
        @tag = tag
        @ctx = ctx
        @opts = []
      end

      # Pushes a new set of options onto the stack for this tag.
      def << opt
        @opts << opt
      end
      alias_method :push, :<<

      # Retrieves the most recent set of options for this tag.
      def opts
        @opts.last || {}
      end

      # Pops the most recent tag off of the stack.
      def pop
        if @opts.empty?
          @ctx.error 'Attempt to close an unopened tag', { :tag => tag }
          nil
        else
          @opts.pop
        end
      end

    end
  end
end
