require_relative 'base'
require_relative 'guetzli_minifier'
require_relative 'image_optim_minifier'
require_relative 'mozjpeg_minifier'

module Inkcite
  module Image
    class ImageMinifier

      # Directory of optimized images
      IMAGE_CACHE = 'images-optim'

      # Common extensions
      GIF = 'gif'
      JPG = 'jpg'
      PNG = 'png'

      def self.minify email, img_name, force=false

        # Original, unoptimized source image
        source_img = File.join(email.image_dir, img_name)

        # Cached, optimized path for this image.
        cache_path = email.project_file(IMAGE_CACHE)
        cached_img = File.join(cache_path, File.basename(img_name))

        # Grab the first file that exists for this project.
        config_path = email.config_file

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

        # Copy the original image to the cache where it can be processed.
        FileUtils.copy(source_img, cached_img)

        # Get the file format (e.g. gif) of the file being optimized.
        source_ext = Util::file_extension(source_img)

        # This will hold the list of minifiers that will be applied to the
        # image, based on its extension.
        pipeline = []

        # True if ImageOptim is allowed to make lossy optimizations to the
        # images.  When false, even if the quality settings allow it, ImageOptim
        # won't make lossy optimizations.
        allow_lossy = true

        if source_ext == JPG
          pipeline << MozjpegMinifier.new
          pipeline << GuetzliMinifier.new
          allow_lossy = false
        end

        # Always optimize with ImageOptim although for JPGs additional
        # lossy compression is force disabled.
        pipeline << ImageOptimMinifier.new(allow_lossy)

        original_size = File.size(source_img)

        msg = "Compressing #{img_name} #{Util.pretty_file_size(original_size)}"

        # Process the image
        pipeline.each do |p|

          # Minifiers don't work well when the source and destination images are the
          # same files - so move the image to a temporary file so the minifier can
          # optimize it back into place.
          temp_img = "#{cached_img}.tmp"
          FileUtils.move(cached_img, temp_img)

          temp_size = File.size(temp_img)

          # Let the processor compress the image
          p.minify!(email, temp_img, cached_img)

          compressed_size = File.size(cached_img)
          if compressed_size < temp_size
            msg << " >> #{p.name} #{Util.pretty_file_size(compressed_size)}"

          else

            # Occassionally the compressor does the wrong thing and
            # makes the image bigger (particularly ImageOptim after
            # Guetzli) so in that case, revert the image to its
            # smaller pre-optimization form.
            FileUtils.copy(temp_img, cached_img)

          end

          # Now remove the temp file.
          FileUtils.remove(temp_img) if File.exists?(temp_img)

        end

        # Get the final compressed size of the image so we can print the
        # resulting compression ratio.
        compressed_size = File.size(cached_img)
        msg << " (#{self.compressed_percent(original_size, compressed_size)}%)"

        Util.log msg

      end

      # Minifies all of the images in the provided email's project directory.
      def self.minify_all email, force=false

        images_path = File.join(email.image_dir, '*.*')

        # Iterate through all of the images in the project and optimize them
        # if necessary.
        Dir.glob(images_path).each do |img|
          self.minify(email, File.basename(img), force)
        end

      end

      def self.compressed_percent original_size, compressed_size
        ((1.0 - (compressed_size / original_size.to_f)) * 100).round(1)
      end

    end
  end
end

