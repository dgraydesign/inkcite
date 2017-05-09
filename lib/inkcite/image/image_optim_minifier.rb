module Inkcite
  module Image
    class ImageOptimMinifier < ImageMinifier::Base

      def initialize allow_lossy=true
        super('ImageOptim')
        @allow_lossy = allow_lossy
      end

      def minify! email, source_img, cache_img

        config = email.config

        img_type = Util::file_extension(cache_img)

        # This will hold the settings that control how imageoptim
        # compresses the image, based on extension.
        optim_opt = {
            :verbose => false,
            :svgo => false
        }

        FileUtils.copy(source_img, cache_img)

        case img_type
          when ImageMinifier::GIF
            mix_gif_options email, config, optim_opt
          when ImageMinifier::JPG
            mix_jpg_options email, config, optim_opt
          when ImageMinifier::PNG
            mix_png_options email, config, optim_opt
          else
            # Don't know how to compress this type of image so
            # just leave it alone
            return
        end

        ImageOptim.new(optim_opt).optimize_image!(cache_img)

      end

      private

      # Name of the configuration field that controls ImageOptim's JPG quality
      IMAGEOPTIM_JPG_QUALITY = :'imageopt-jpg-quality'

      # Default JPG image quality
      DEFAULT_JPG_QUALITY = 85

      # Quality constraints
      MIN_QUALITY = 0
      MAX_QUALITY = 100

      def mix_gif_options email, config, opts

      end

      def mix_jpg_options email, config, opts

        max_quality = get_jpg_quality(config, IMAGEOPTIM_JPG_QUALITY, DEFAULT_JPG_QUALITY)

        # Anything less than 100% quality means lossy is enabled.
        lossy = @allow_lossy && max_quality < 100
        opts[:allow_lossy] = lossy

        # Additional configuration necessary only if lossy compression
        # is enabled.  Otherwise, the defaults are acceptable.
        if lossy
          opts[:jpegoptim] = {
              :allow_lossy => lossy,
              :max_quality => max_quality
          }

          opts[:jpegrecompress] = {
              :allow_lossy => lossy,
              :quality => (max_quality / 100.0 * 3).round(0)
          }
        end


      end

      def mix_png_options email, config, opts

      end


    end
  end
end
