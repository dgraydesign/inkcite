module Inkcite
  module Renderer
    class Increment < Base

      def render tag, opt, ctx

        # Get the unique ID for which a counter will be incremented.
        # Or use the default value.
        id = opt[:id] || DEFAULT
        ctx.unique_id(id).to_s

      end

      private

      # Tip o' the hat to the most-used index variable name.
      DEFAULT = 'i'

    end
  end
end
