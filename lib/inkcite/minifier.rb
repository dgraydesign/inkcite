require 'image_optim'
require 'yui/compressor'

module Inkcite
  class Minifier

    # Directory of optimized images
    IMAGE_CACHE = "images-optim"

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

    def self.images email, force=false

      images_path = email.image_dir
      cache_path = email.project_file(IMAGE_CACHE)

      # Check to see if there is an image optim configuration file.
      config_path = email.project_file(IMAGE_OPTIM_CONFIG_YML)
      config_last_modified = Util.last_modified(config_path)

      # If the image cache exists, we need to check to see if any images have been
      # removed since the last build.
      if File.exists?(cache_path)

        # Get a list of the files in the cache that do not also exist in the
        # project's images/ directory.
        removed_images = Dir.entries(cache_path) - Dir.entries(images_path)
        unless removed_images.blank?

          # Convert the images to fully-qualified paths and then remove
          # those files from the cache
          removed_images = removed_images.collect { |img| File.join(cache_path, img) }
          FileUtils.rm(removed_images)

        end

      end

      # Check to see if there are new or updated images that need to be re-optimized.
      # Compare existing images against both the most recently cached version and
      # the timestamp of the config file.
      updated_images = Dir.glob(File.join(images_path, '*.*')).select do |img|
        cached_img = File.join(cache_path, File.basename(img))
        cache_last_modified = Util.last_modified(cached_img)
        force || config_last_modified > cache_last_modified || Util.last_modified(img) > cache_last_modified
      end

      # Return unless there is something to compress
      return if updated_images.blank?

      FileUtils.mkpath(cache_path)

      # Check to see if there is an image_optim.yml file in this directory that
      # overrides the default settings.
      image_optim_opts = if config_last_modified > 0
        {
            :config_paths => [IMAGE_OPTIM_CONFIG_YML]
        }
      else
        {
            :allow_lossy => true,
            :gifsicle => { :level => 3 },
            :jpegoptim => { :max_quality => 50 },
            :jpegrecompress => { :quality => 1 },
            :pngout => false,
            :svgo => false
        }
      end

      image_optim = ImageOptim.new(image_optim_opts)

      # Copy all of the images that need updating into the temporary directory.
      # Specifically joining the images_path to the image to avoid Email's
      # image_path which may change it's directory if optimization is enabled.
      updated_images.each do |img|
        cached_img = File.join(cache_path, File.basename(img))
        FileUtils.cp(img, cached_img)
        image_optim.optimize_image!(cached_img)
      end

    end

    def self.js code, ctx
      minify?(ctx) ? js_compressor(ctx).compress(code) : code
    end

    private

    # Name of the Image Optim configuration yml file that can be
    # put in the project directory to explicitly control the image
    # optimization process.
    IMAGE_OPTIM_CONFIG_YML = 'image_optim.yml'


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
      ctx.css_compressor ||= YUI::CssCompressor.new(:line_break => (ctx.email? ? MAXIMUM_LINE_LENGTH : nil))
    end

  end
end
