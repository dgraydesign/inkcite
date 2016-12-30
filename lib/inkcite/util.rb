# Includes hex color manipulation from
# http://www.redguava.com.au/2011/10/lighten-or-darken-a-hexadecimal-color-in-ruby-on-rails/
module Inkcite
  module Util

    def self.add_query_param href, value

      # Start with either a question mark or an ampersand depending on
      # whether or not there is already a question mark in the URI.
      param = href.include?('?') ? '&' : '?'
      param << value.to_s

      if hash_position = href.index('#')
        href[hash_position..0] = param
      else
        href << param
      end

      href
    end

    def self.brightness_value color
      color.nil? ? 0 : (color.gsub('#', '').scan(/../).map { |c| c.hex }).inject { |sum, c| sum + c }
    end

    def self.darken color, amount=0.4
      return BLACK if color.nil?
      rgb = color.gsub('#', '').scan(/../).map { |c| c.hex }
      rgb[0] = (rgb[0].to_i * amount).round
      rgb[1] = (rgb[1].to_i * amount).round
      rgb[2] = (rgb[2].to_i * amount).round
      "#%02x%02x%02x" % rgb
    end

    # Iterates through the list of possible options and returns the
    # first non-blank value.
    def self.detect *opts
      opts.detect { |o| !o.blank? }
    end

    # Centralizing the URL/CGI encoding for all HREF processing because
    # URI.escape/encode is obsolete.
    def self.encode *arg
      silence_warnings do
        URI.escape(*arg)
      end
    end

    def self.escape *arg
      silence_warnings do
        URI.escape(*arg)
      end
    end

    def self.lighten color, amount=0.6
      return WHITE if color.nil?
      rgb = color.gsub('#', '').scan(/../).map { |c| c.hex }
      rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
      rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
      rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
      "#%02x%02x%02x" % rgb
    end

    def self.contrasting_text_color color
      brightness_value(color) > 382.5 ? darken(color) : lighten(color)
    end

    def self.each_line path, fail_if_not_exists, &block

      if File.exist?(path)
        File.open(path).each { |line| yield line.strip }
      elsif fail_if_not_exists
        raise "File not found: #{path}"
      end

    end

    def self.is_fully_qualified? href
      href.include?('//')
    end

    def self.last_modified file
      file && File.exist?(file) ? File.mtime(file).to_i : 0
    end

    def self.read *argv
      path = File.join(File.expand_path('../..', File.dirname(__FILE__)), argv)
      if File.exist?(path)
        line = File.open(path).read
        line.gsub!(/[\r\f\n]+/, "\n")
        line.gsub!(/ {2,}/, ' ')
        line
      end
    end

    def self.read_yml file, opts={}
      if File.exist?(file)
        yml = YAML.load_file(file)
        symbolize_keys(yml) unless opts[:symbolize_keys] == false
        yml
      elsif opts[:fail_if_not_exists]
        raise "File not found: #{file}"
      else
        {}
      end
    end

    private

    BLACK = '#000000'
    WHITE = '#111111'

    # Recursive key symbolization for the provided Hash.
    def self.symbolize_keys hash
      unless hash.nil?
        hash.symbolize_keys!
        hash.each do |k, v|
          symbolize_keys(v) if v.is_a?(Hash)
        end
      end
      hash
    end

  end
end
