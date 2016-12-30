module Inkcite
  class Minifier

    # Directory of optimized images
    IMAGE_CACHE = "images-optim"

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

          # Position at which a line break will be inserted at.
          break_at = 0

          # Work through the code injecting line breaks until either no further
          # breakable characters are found or we've reached the end of the code.
          while break_at < code.length
            break_at = code.rindex(/[;}]/, break_at + MAXIMUM_LINE_LENGTH) + 1
            code.insert(break_at, "\n") if break_at && break_at < code.length
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

    def self.images email, force=false

      images_path = email.image_dir
      cache_path = email.project_file(IMAGE_CACHE)

      # Check to see if there is an image optim configuration file.
      config_path = email.project_file(IMAGE_OPTIM_CONFIG_YML)
      config_last_modified = Util.last_modified(config_path)

      # If the image cache exists, we need to check to see if any images have been
      # removed since the last build.
      if File.exist?(cache_path)

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

    def self.remove_comments html, ctx
      remove_comments?(ctx) ? html.gsub(HTML_COMMENT_REGEX, '') : html
    end

    private

    # Name of the Image Optim configuration yml file that can be
    # put in the project directory to explicitly control the image
    # optimization process.
    IMAGE_OPTIM_CONFIG_YML = 'image_optim.yml'

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
