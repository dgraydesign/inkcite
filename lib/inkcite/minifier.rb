require 'yui/compressor'

module Inkcite
  class Minifier

    # Directory of optimized images
    IMAGE_CACHE = ".images"

    def self.css code, ctx
      minify?(ctx) ? css_compressor(ctx).compress(code) : code
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

    def self.images email

      image_optim_path = '/Applications/ImageOptim.app/Contents/MacOS/ImageOptim'
      image_optim = File.exists?(image_optim_path)
      abort "Can't find ImageOptim (#{image_optim_path}) - download it from https://imageoptim.com" unless image_optim

      images_path = email.image_dir
      cache_path = email.project_file(IMAGE_CACHE)

      # If the image cache exists, we need to check to see if any images have been
      # removed since the last build.
      if File.exists?(cache_path)

        # Get a list of the files in the cache that do not also exist in the
        # project's images/ directory.
        removed_images = Dir.entries(cache_path) - Dir.entries(images_path)
        unless removed_images.blank?

          # Convert the images to fully-qualified paths and then remove
          # those files from the cache
          removed_images = removed_images.collect { |img| File.join(cache_path, img ) }
          FileUtils.rm (removed_images)

        end

      end

      # Check to see if there are new or updated images that need to be re-optimized.
      updated_images = Dir.entries(images_path).select do |img|
        unless img.start_with?('.')
          cimg = File.join(cache_path, img)
          !File.exists?(cimg) || (File.stat(File.join(images_path, img)).mtime > File.stat(cimg).mtime)
        end
      end

      return if updated_images.blank?

      # This is the temporary path into which new or updated images will
      # be copied and then optimized.
      temp_path = email.project_file(IMAGE_TEMP)

      # Make sure there is no existing temporary directory to interfere
      # with the image processing.
      FileUtils.rm_rf(temp_path)
      FileUtils.mkpath(temp_path)

      # Copy all of the images that need updating into the temporary directory.
      # Specifically joining the images_path to the image to avoid Email's
      # image_path which may change it's directory if optimization is enabled.
      updated_images.each { |img| FileUtils.cp(File.join(images_path, img), File.join(temp_path, img)) }

      # Optimize all of the images.
      system("#{image_optim_path} #{temp_path}") if image_optim

      FileUtils.cp_r(File.join(temp_path, "."), cache_path)
      FileUtils.rm_rf(temp_path)

    end

    def self.js code, ctx
      minify?(ctx) ? js_compressor(ctx).compress(code) : code
    end

    private

    # Temporary directory that new or updated images will be copied into
    # to be optimized and then cached in .images
    IMAGE_TEMP = ".images-temp"

    NEW_LINE = "\n"
    MAXIMUM_LINE_LENGTH = 800

    # Used to match inline styles that will be compressed when minifying
    # the entire email.
    INLINE_STYLE_REGEX = /style=\"([^\"]+)\"/

    def self.minify? ctx
      ctx.is_enabled?(:minify)
    end

    def self.js_compressor ctx
      ctx.js_compressor ||= YUI::JavaScriptCompressor.new(:munge => true)
    end

    def self.css_compressor ctx
      ctx.css_compressor ||= YUI::CssCompressor.new(:line_break => (ctx.email?? MAXIMUM_LINE_LENGTH : nil))
    end

  end
end
