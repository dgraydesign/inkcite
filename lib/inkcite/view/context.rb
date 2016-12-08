module Inkcite
  class View

    # Private class used to convey view attributes to the Erubis rendering
    # engine without exposing all of the view's attributes.
    class Context

      delegate :browser?, :development?, :email?, :environment, :format, :production?, :preview?, :version, :to => :view

      def initialize view
        @view = view
      end

      # Defines a new helper via ERB, which allows designers to keep helper
      # markup alongside the usage of it inside of partial.  Helps keep
      # code clean and prevents helper.tsv pollution for one-offs
      def helper tag, open, close=nil

        tag = tag.to_sym

        # The config object holds the defined helpers
        config = @view.config

        # Warn the user if the helper is already defined.
        view.error("Helper '#{tag}' already defined", :open => open, :close => close) unless config[tag].nil?

        config[tag] = open.to_s
        config[:"/#{tag}"] = close.to_s

      end

      def once? key

        # Initialize the 'once' data hash which maps
        @view.data[:once] ||= {}

        # True if this is the first time we've encountered this key.
        first_time = @view.data[:once][key].nil?
        @view.data[:once][key] = true if first_time

        first_time
      end

      def method_missing(m, *args, &block)
        if m[-1] == QUESTION_MARK
          start_at = m[0] == UNDERSCORE ? 1 : 0
          symbol = m[start_at, m.length - (start_at + 1)].to_sym

          @view.version == symbol
        else
          super
        end
      end

      protected

      def view
        @view
      end

      private

      UNDERSCORE = '_'
      QUESTION_MARK = '?'

    end
  end
end
