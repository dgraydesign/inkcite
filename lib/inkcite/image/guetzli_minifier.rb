module Inkcite
  module Image
    class GuetzliMinifier < ImageMinifier::Base

      def initialize
        super('Guetzli')
      end

      def minify! email, source_img, cache_img

        # Grab the full path to the guetzli binary
        guetzli_path = `which guetzli`.delete("\n")
        unless guetzli_path.blank?

          cmd = []
          cmd << guetzli_path

          config = email.config

          quality = get_jpg_quality(config, GUETZLI_QUALITY, DEFAULT_QUALITY)
          if quality > 0 && quality < MAX_QUALITY

            # Per the Guetzli documentation, a value less than 84 isn't useful.
            quality = MIN_GUETZLI_QUALITY if quality < MIN_GUETZLI_QUALITY
            cmd << "--quality #{quality}"

          end

          cmd << %Q("#{source_img}")
          cmd << %Q("#{cache_img}")

          Util::exec(cmd)

          true

        else

          # No guetzli, so simply move the source image into the destination
          # position without compression.
          FileUtils.copy(source_img, cache_img)

          false
        end


      end

      private

      # Default quality is zero - which lets Guetzli decide how best to
      # optimize the image.
      DEFAULT_QUALITY = 0

      # The minimum quality setting per the Guetzli runtime.
      MIN_GUETZLI_QUALITY = 84

      # Configuration field names
      GUETZLI_QUALITY = :'guetzli-quality'

    end
  end
end
