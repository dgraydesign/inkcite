require 'yui/compressor'

module Inkcite
  class Minifier

    def self.css code, ctx
      minify?(ctx) ? css_compressor.compress(code) : code
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
      minify?(ctx) ? js_compressor.compress(code) : code
    end

    private

    NEW_LINE = "\n"
    MAXIMUM_LINE_LENGTH = 800

    # Used to match inline styles that will be compressed when minifying
    # the entire email.
    INLINE_STYLE_REGEX = /style=\"([^\"]+)\"/

    def self.minify? ctx
      ctx.is_enabled?(:minify)
    end

    def self.js_compressor
      @yui_js ||= YUI::JavaScriptCompressor.new(:munge => true)
    end

    def self.css_compressor
      @yui_css ||= YUI::CssCompressor.new
    end

  end
end
