module Inkcite
  module Renderer
    class Footnote < Base

      class Instance

        # Optional, unique ID assigned by the designer for this footnote
        # so that a numeric footnote can be referenced repeatedly,
        # non-linearly throughout the email.
        attr_reader :id

        # Symbol associated with the footnote.  Typically going to be
        # numeric but could be a user-specified symbol - e.g. †.
        attr_reader :symbol

        # The message associated with the footnote that will be displayed
        # when the {footnotes} tag is rendered.
        attr_reader :text

        def initialize id, symbol, text
          @id = id
          @symbol = symbol.to_s
          @text = text
        end

        def number
          @symbol.to_i
        end

        # Returns true if this footnote is numeric rather than
        # a symbol - e.g. †
        def numeric?
          @symbol == @symbol.to_i.to_s
        end

        def to_s
          "#{symbol} #{text}"
        end

      end

      def render tag, opt, ctx

        # Grab the optional id for this footnote.  This would only be
        # populated if the designer intends on referencing this footnote
        # in multiple spots.
        id = opt[:id] || opt[:name]

        # If an id was specified, check to see if an existing footnote has
        # already been associated with this.
        instance = ctx.footnotes.detect { |f| f.id == id } unless id.blank?
        unless instance

          # Grab the optional symbol that was specified by the designer.  If
          # this isn't specified count the number of existing numeric footnotes
          # and increment it for this new footnote's symbol.
          symbol = opt[:symbol]
          if symbol.blank?

            # Grab the last numeric footnote that was specified and, assuming
            # there is one, increment the count.  Otherwise, start the count
            # off at one.
            last_instance = ctx.footnotes.select(&:numeric?).last
            symbol = last_instance.nil?? 1 : last_instance.symbol.to_i + 1

          end

          # Grab the text associated with this footnote.
          text = opt[:text]
          ctx.error("Footnote requires text attribute", { :id => id, :symbol => symbol }) if text.blank?

          # Create a new Footnote instance
          instance = Instance.new(id, symbol, text)

          # Push the new footnote onto the stack.
          ctx.footnotes << instance

        end

        "#{instance.symbol}"
      end

    end

    class Footnotes < Base
      def render tag, opt, ctx

        # Nothing to do if footnotes are blank.
        return if ctx.footnotes.blank?

        # Check to see if a template has been provided.  Otherwise use a default one based
        # on the format of the email.
        tmpl = opt[:tmpl] || opt[:template]
        if tmpl.blank?
          tmpl = '$symbol$. $text$'
          tmpl << (ctx.text?? "\n\n" : '<br><br>')
        end

        # Symbolic footnotes (e.g. daggers) always go ahead of
        # the numeric footnotes - cause that's the way I like it
        # uh huh, uh huh.
        ctx.footnotes.sort! do |f1, f2|

          next 1 if f1.numeric? && !f2.numeric?
          next -1 if !f1.numeric? && f2.numeric?
          f1.number <=> f2.number

        end

        html = ''

        # Iterate through each of the footnotes and render them based on the
        # template that was provided.
        ctx.footnotes.collect do |f|
          html << tmpl.gsub('$symbol$', f.symbol).gsub('$text$', f.text)
        end

        html
      end
    end

  end
end
