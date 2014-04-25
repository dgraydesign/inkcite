# Includes hex color manipulation from
# http://www.redguava.com.au/2011/10/lighten-or-darken-a-hexadecimal-color-in-ruby-on-rails/
module Inkcite
  module Util

    def self.brightness_value color
      color.nil?? 0 : (color.gsub('#', '').scan(/../).map { |c| c.hex }).inject { |sum, c| sum + c }
    end

    def self.darken color, amount=0.4
      return BLACK if color.nil?
      rgb = color.gsub('#', '').scan(/../).map { |color| color.hex }
      rgb[0] = (rgb[0].to_i * amount).round
      rgb[1] = (rgb[1].to_i * amount).round
      rgb[2] = (rgb[2].to_i * amount).round
      "#%02x%02x%02x" % rgb
    end

    def self.lighten color, amount=0.6
      return WHITE if color.nil?
      rgb = color.gsub('#', '').scan(/../).map { |color| color.hex }
      rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
      rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
      rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
      "#%02x%02x%02x" % rgb
    end

    def self.contrasting_text_color color
      brightness_value(color) > 382.5 ? darken(color) : lighten(color)
    end

    def self.each_line path, fail_if_not_exists, &block

      if File.exists?(path)
        File.open(path).each { |line| yield line.strip }
      elsif fail_if_not_exists
        raise "File not found: #{path}"
      end

    end

    def self.read *argv
      path = File.join(File.expand_path('../..', File.dirname(__FILE__)), argv)
      if File.exists?(path)
        line = File.open(path).read
        line.gsub!(/[\r\f\n]+/, "\n")
        line.gsub!(/ {2,}/, ' ')
        line
      end
    end

    def self.read_yml file, fail_if_not_exists=false
      if File.exist?(file)
        symbolize_keys(YAML.load_file(file))
      elsif fail_if_not_exists
        raise "File not found: #{file}" if fail_if_not_exists
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
