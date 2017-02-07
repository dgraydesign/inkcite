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

    # Conversion of HSL to RGB color courtesy of
    # http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
    def self.hsl_to_color h, s, l

      # The algorithm expects h, s and l to be values between 0-1.
      h = h / 360.0
      s = s / 100.0
      l = l / 100.0

      # Wrap the color wheel if the hue provided is less than or
      # greater than 1
      h += 1.0 while h < 0
      h -= 1.0 while h > 1

      s = 0.0 if s < 0
      s = 1.0 if s > 1

      l = 0.0 if l < 0
      l = 1.0 if l > 1

      r = g = b = 0

      if s == 0
        r = g = b = l

      else
        q = l < 0.5 ? l * (1 + s) : l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1/3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3.0)

      end

      r = (r * 255).round(0)
      g = (g * 255).round(0)
      b = (b * 255).round(0)

      "##{rgb_to_hex(r)}#{rgb_to_hex(g)}#{rgb_to_hex(b)}"
    end

    def self.hue_to_rgb p, q, t
      t += 1 if t < 0
      t -= 1 if t > 1
      return (p + (q - p) * 6.0 * t) if (t < 1.0/6.0)
      return q if (t < 0.5)
      return (p + (q - p) * (2/3.0 - t) * 6) if (t < 2/3.0)
      p
    end

    # RGB to hex courtesy of
    # http://blog.lebrijo.com/converting-rgb-colors-to-hexadecimal-with-ruby/
    def self.rgb_to_hex val
      val.to_s(16).rjust(2, '0').downcase
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
