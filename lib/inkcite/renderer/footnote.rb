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

        # True if this footnote is active. By default all footnotes are
        # activate but those read from footnotes.tsv are inactive until
        # referenced in the source.
        attr_accessor :active
        alias_method :active?, :active

        def initialize id, symbol, text, active=true
          @id = id
          @symbol = symbol.to_s
          @text = text
          @active = active
        end

        def number
          @symbol.to_i
        end

        # Returns true if this footnote is numeric rather than
        # a symbol - e.g. †
        def numeric?
          @symbol == @symbol.to_i.to_s
        end

        def symbol=symbol
          @symbol = symbol.to_s
        end

        def symbol?
          !numeric?
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

          # Grab the text associated with this footnote.
          text = opt[:text]
          if text.blank?
            ctx.error("Footnote requires text attribute", { :id => id, :symbol => symbol })
            return
          end

          # Create a new Footnote instance
          instance = Instance.new(id, symbol, text)

          # Push the new footnote onto the stack.
          ctx.footnotes << instance

        end

        # Check to see if the footnote's symbol is blank (either because one
        # wasn't defined in the source.html or because the one read from the
        # footnotes.tsv had no symbol associated with it) and if so, generate
        # one based on the number of previously declared numeric footnotes.
        if instance.symbol.blank?

          # Grab the last numeric footnote that was specified and, assuming
          # there is one, increment the count.  Otherwise, start the count
          # off at one.
          last_instance = ctx.footnotes.select { |fn| fn.numeric? && fn.active? }.collect(&:number).max.to_i
          instance.symbol = last_instance + 1

        end

        # Make sure the instance is marked as having been used so it will
        # appear in the {footnotes} rendering.
        instance.active = true

        # Allow footnotes to be defined without showing a symbol
        hidden = opt[:hidden] || (opt[:hidden] == '1')
        "#{instance.symbol}" unless hidden
      end

    end

    class Footnotes < Base
      def render tag, opt, ctx

        # Nothing to do if footnotes are blank.
        return if ctx.footnotes.blank?

        # Grab the active footnotes.
        active_footnotes = ctx.footnotes.select(&:active)
        return if active_footnotes.blank?

        # Check to see if a template has been provided.  Otherwise use a default one based
        # on the format of the email.
        tmpl = opt[:tmpl] || opt[:template]
        if tmpl.blank?
          tmpl = ctx.text? ? "($symbol$) $text$\n\n" : "<sup>$symbol$</sup> $text$<br><br>"

        elsif ctx.text?

          # If there are new-lines encoded in the custom template, make sure
          # they get converted to real new lines.
          tmpl.gsub!('\\n', "\n")

        end

        # For the emailed version, append a line break between each footnote so that we don't
        # end up with lines that exceed the allowed limit in certain versions of Outlook.
        tmpl << "\n" if ctx.email?

        # First, collect all symbols in the natural order they are defined
        # in the email.
        footnotes = active_footnotes.select(&:symbol?)

        # Now add to the list all numeric footnotes ordered naturally
        # regardless of how they were ordered in the email.
        footnotes += active_footnotes.select(&:numeric?).sort { |f1, f2| f1.number <=> f2.number }

        html = ''

        # Iterate through each of the footnotes and render them based on the
        # template that was provided.
        footnotes.each do |f|
          html << tmpl.gsub('$symbol$', f.symbol).gsub('$text$', f.text)
        end

        html
      end
    end

  end
end
