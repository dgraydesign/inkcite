module Inkcite
  module Image
    class ImageMinifier

      # Base class for all image minifiers in the optimization pipeline
      class Base

        attr_reader :name

        def initialize name
          @name = name
        end

        def minify! email, source_img, cache_img
          raise 'The extending class must implement this method'
        end

        protected

        # Common configuration names
        JPG_QUALITY = :'jpg-quality'

        # JPG quality bounds
        MIN_QUALITY = 0
        MAX_QUALITY = 100

        def get_jpg_quality config, override_key, default
          quality = (config[override_key] || config[JPG_QUALITY] || default).to_i
          quality = MIN_QUALITY if quality < MIN_QUALITY
          quality = MAX_QUALITY if quality > MAX_QUALITY
          quality
        end

      end

    end
  end
end
