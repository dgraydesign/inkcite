module Inkcite
  class Parser

    def self.each str, regex=BRACKET_REGEX, &block

      # Make sure we're dealing with a string.
      str = str.to_s

      # If the string provided is frozen, we need to duplicate it because we
      # don't want to modify the original.
      str = str.dup if str.frozen?

      # Counts the number of replacements and prevents an infinite loop.
      failsafe = 0

      # While there are matches within the string, repeatedly iterate.
      while match = regex.match(str)

        # Get the position, as an array, of the match within the string.
        offset = match.offset(0)

        # Provide the block with the area that was matched, sans wrapper brackets.
        # Replace the brackets and original value with the block's results.
        result = yield(match[1].to_s) || EMPTY_STRING
        str[offset.first, offset.last - offset.first] = result

        # Ensure we don't infinite loop.
        failsafe += 1
        raise "Infinite replacement detected: #{failsafe} #{str}" if failsafe >= MAX_RECURSION
      end

      str
    end

    def self.parameters str

      # Add an extra space to the end to ensure that the last parameter
      # gets parsed correctly.
      str = str.to_s + SPACE

      # Will hold the parameters successfully parsed.
      params = { }

      # True if we're within a quoted value.
      quote = false

      # Will hold each key and value we find.
      key = nil

      # This will hold the substring that is assembled - it will either be the
      # key (when an equals in encountered) or the value (when a space or closing
      # quote is discovered).
      value = ''

      length = str.length - 1
      for i in 0..length

        # Read the next character in the string.
        chr = str[i]

        if chr == QUOTE

          # Each time a quote is discovered, toggle the flag indicating that we're
          # inside of a value or (when false) we're assembling a key.
          quote = !quote

        elsif chr == EQUAL && !quote

          # When an equal sign is encountered and we're not inside of a quote, then
          # convert the assembled value into a symbolized key.
          unless value.blank?
            key = value.to_sym
            value = ''
          end

        elsif chr == SPACE && !quote

          # When a space is encountered, if we're not inside of a quote block then
          # assign the assembled value to the previously discovered key.
          if key
            params[key] = value
            value = ''
            key = nil
          end

        else
          value << chr

        end

      end

      params
    end

    private

    # When the handler returns nil
    EMPTY_STRING = ''

    # We fail if we recurse through a property more than this many times.
    MAX_RECURSION = 1000

    BRACKET_REGEX = /\{([^\{\}]+)\}/

    SPACE = ' '
    QUOTE = '"'
    EQUAL = '='

  end
end
