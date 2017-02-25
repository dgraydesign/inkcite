module Inkcite
  class Minifier

    # Directory of optimized images
    IMAGE_CACHE = 'images-optim'

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

    def self.image email, img_name, force=false

      # Original, unoptimized source image
      source_img = File.join(email.image_dir, img_name)

      # Cached, optimized path for this image.
      cache_path = email.project_file(IMAGE_CACHE)
      cached_img = File.join(cache_path, File.basename(img_name))

      # Full path to the local project's kraken config if it exists
      kraken_config_path = email.project_file(KRAKEN_CONFIG_YML)

      # This is the array of config files that will be searched to
      # determine which algorithm to use to compress the images.
      config_paths = [
          kraken_config_path,
          email.project_file(IMAGE_OPTIM_CONFIG_YML),
          File.join(Inkcite.asset_path, 'init', IMAGE_OPTIM_CONFIG_YML)
      ]

      # Grab the first file that exists for this project.
      config_path = config_paths.detect { |p| File.exist?(p) }

      unless force

        # Get the last-modified date of the image optimization config
        # file - if that file is newer than the image, re-optimization
        # is necessary because the settings have changed.
        config_last_modified = Util.last_modified(config_path)

        # Get the last-modified date of the actual image.  If the source
        # image is newer than the cached version, we'll need to run it
        # through optimization again, too.
        cache_last_modified = Util.last_modified(cached_img)
        source_last_modified = Util.last_modified(source_img)

        # Nothing to do unless the image in the cache is older than the
        # source or the config file.
        return unless config_last_modified > cache_last_modified || source_last_modified > cache_last_modified

      end

      # Make sure the image cache directory exists
      FileUtils.mkpath(cache_path)

      # Read the image compression configuration settings
      config = Util::read_yml(config_path, :fail_if_not_exists => false)

      if config_path == kraken_config_path
        minify_with_kraken_io email, config, source_img, cached_img

      else

        # Default image optimization uses built-in ImageOptim
        minify_with_image_optim email, config, source_img, cached_img

      end

      original_size = File.size(source_img)
      compressed_size = File.size(cached_img)
      percent_compressed = ((1.0 - (compressed_size / original_size.to_f)) * 100).round(1)
      puts "Compressed #{img_name} #{percent_compressed}%"

    end

    def self.images email, force=false

      images_path = email.image_dir

      # Iterate through all of the images in the project and optimize them
      # if necessary.
      Dir.glob(File.join(images_path, '*.*')).each { |img| self.image(email, File.basename(img), force) }

    end

    def self.js code, ctx
      minify?(ctx) ? js_compressor(ctx).compress(code) : code
    end

    def self.remove_comments html, ctx
      remove_comments?(ctx) ? html.gsub(HTML_COMMENT_REGEX, '') : html
    end

    private

    def self.minify_with_image_optim email, config, source_img, cached_img

      # Copy the image into the destination directory and then use Image Optim
      # to optimize it in place.
      FileUtils.cp(source_img, cached_img)
      ImageOptim.new(config).optimize_image!(cached_img)

    end

    def self.minify_with_kraken_io email, config, source_img, cached_img

      require 'kraken-io'
      require 'open-uri'

      # Initialize the Kraken API using the API key and secret defined in the
      # config.yml file.
      kraken = Kraken::API.new(
          :api_key => config[:api_key],
          :api_secret => config[:api_secret]
      )

      # As you might expect, Outlook doesn't support webp so it needs to be
      # disabled by default.  Otherwise, Kraken always compresses with webp.
      kraken_opts = { :webp => false }

      # Get the file format (e.g. gif) of the file being optimized.
      source_fmt = File.extname(source_img).delete('.')

      # True if the configuration file does not specifically exclude
      # this format from being processed.
      compress_this_fmt = config[source_fmt.to_sym] != false

      # Typically, we're going to want lossy compression to minify the file
      # but if the user has put lossy: false specifically in their config
      # file, we'll disable that feature in Kraken too.  Defaults to true.
      kraken_opts[:lossy] = compress_this_fmt

      # Send the quality metric to Kraken only if specified.  Per their
      # documentation, Kraken will attempt to guess the best quality to
      # use but in my experience it errs on the side of higher quality
      # whereas setting a quality factor around 50 produces a good
      # balance of image detail and file size.
      if compress_this_fmt
        quality = config[:quality].to_i
        kraken_opts[:quality] = quality if quality > 0 and quality <= 100
      end

      # Upload the image to Kraken which blocks by default until the image
      # has been optimized.
      data = kraken.upload(source_img, kraken_opts)
      if data.success
        File.write(cached_img, open(data.kraked_url).read, { :mode => 'wb' })
      else
        puts "Failed to optimize #{img_name}: #{data.message}"
      end

    end

    # Name of the Image Optim configuration yml file that can be
    # put in the project directory to explicitly control the image
    # optimization process.
    IMAGE_OPTIM_CONFIG_YML = 'image_optim.yml'

    # Name of the Kraken configuration yml that, when present in
    # the project directory and populated with an API key and secret
    # causes Kraken.io paid image optimization service to be used.
    KRAKEN_CONFIG_YML = 'kraken.yml'

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
