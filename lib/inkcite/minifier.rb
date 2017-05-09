require_relative 'image/image_minifier'

module Inkcite
  class Minifier

    # Maximum line length for CSS and HTML - lines exceeding this length cause
    # problems in certain email clients.
    MAXIMUM_LINE_LENGTH = 800

    def self.css code, ctx

      # Do nothing to the code unless minification is enabled.
      if minify?(ctx)

        # After YUI's CSS compressor started introducing problems into CSS3
        # animations, I've switched to a homegrown, extremely simple compression
        # algorithm for CSS.  Instead of messing with parameters, we're simply
        # eliminating whitespace.

        # Replace all line breaks with spaces
        code.gsub!(/[\n\r\f]/, ' ')

        # Remove whitespace at the beginning or ending of the code
        code.gsub!(/^\s+/, '')
        code.gsub!(/\s+$/, '')

        # Compress multiple whitespace characters into a single space.
        code.gsub!(/\s{2,}/, ' ')

        # Remove whitespace preceding or following open and close curly brackets.
        code.gsub!(/\s*([{};:])\s*/, "\\1")

        # Remove semicolons preceding close brackets.
        code.gsub!(';}', '}')

        # Certain versions of outlook have a problem with excessively long lines
        # so if this minified code now exceeds the maximum line limit, re-introduce
        # wrapping in spots where it won't break anything to do so - e.g. following
        # a semicolon or close bracket.
        if ctx.email? && code.length > MAXIMUM_LINE_LENGTH

          # Last position at which a line break was be inserted at.
          last_break_at = 0

          # Work through the code injecting line breaks until either no further
          # breakable characters are found or we've reached the end of the code.
          while last_break_at < code.length
            break_at = code.rindex(/[ ,;{}]/, last_break_at + MAXIMUM_LINE_LENGTH)

            # No further characters match (unlikely) or an unbroken string since
            # the last time a break was injected.  Either way, let's get out.
            break if break_at.nil? || break_at <= last_break_at

            # If we've found a space we can break at, do a direct replacement of the
            # space with a new line.  Otherwise, inject a new line one spot after
            # the matching character.
            if code[break_at] == ' '
              code[break_at] = NEW_LINE

            else
              break_at += 1
              code.insert(break_at, NEW_LINE)
              break_at += 1
            end

            last_break_at = break_at
          end

        end

      end

      code
    end

    def self.html lines, ctx

      if minify?(ctx)

        # Will hold the assembled, minified HTML as it is prepared.
        html = ''

        # Will hold the line being assembled until it reaches the maximum
        # allowed line length.
        packed_line = ''

        lines.each do |line|
          next if line.blank?

          line.strip!

          ## Compress all in-line styles.
          #Parser.each line, INLINE_STYLE_REGEX do |style|
          #  style.gsub!(/: +/, ':')
          #  style.gsub!(/; +/, ';')
          #  style.gsub!(/;+/, ';')
          #  style.gsub!(/;+$/, '')
          #  "style=\"#{style}\""
          #end

          # If the length of the packed line with the addition of this line of content would
          # exceed the maximum allowed line length, then push the collected lines onto the
          # html and start a new line.
          if !packed_line.blank? && packed_line.length + line.length > MAXIMUM_LINE_LENGTH
            html << packed_line
            html << NEW_LINE
            packed_line = ''
          end

          packed_line << ' ' unless packed_line.blank?
          packed_line << line

        end

        # Make sure to get any last lines assembled on the packed line.
        html << packed_line unless packed_line.blank?

        html
      else
        lines.join(NEW_LINE)

      end

    end

    def self.js code, ctx
      minify?(ctx) ? js_compressor(ctx).compress(code) : code
    end

    def self.remove_comments html, ctx
      remove_comments?(ctx) ? html.gsub(HTML_COMMENT_REGEX, '') : html
    end

    private

    NEW_LINE = "\n"

    # Used to match inline styles that will be compressed when minifying
    # the entire email.
    INLINE_STYLE_REGEX = /style=\"([^\"]+)\"/

    # Regex to match HTML comments when removal is necessary. The ? makes
    # the regex ungreedy.  The /m at the end ensures the regex matches
    # multiple lines.
    HTML_COMMENT_REGEX = /<!--(.*?)-->/m

    def self.minify? ctx
      ctx.is_enabled?(:minify)
    end

    # Config attribute that allows for comment striping to be disabled.
    # e.g. strip-comments: false
    def self.remove_comments? ctx
      minify?(ctx) && !ctx.is_disabled?(:'strip-comments')
    end

    def self.js_compressor ctx
      ctx.js_compressor ||= YUI::JavaScriptCompressor.new(:munge => true)
    end

  end
end
