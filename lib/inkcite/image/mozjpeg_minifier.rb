require 'mozjpeg'

module Inkcite
  module Image
    class MozjpegMinifier < ImageMinifier::Base

      def initialize
        super('Mozjpeg')
      end

      def minify! email, source_img, cache_img

        config = email.config

        cmd = []

        # mozjpeg usage documentation available
        # https://github.com/mozilla/mozjpeg/blob/master/usage.txt
        cmd << Mozjpeg.cjpeg_path

        chrominance_quality = get_jpg_quality(config, MOZJPEG_CHROMINANCE_QUALITY, DEFAULT_QUALITY)

        # The human eye is more sensitive to spatial changes in brightness than
        # spatial changes in color, the chrominance components can be quantized more
        # than the luminance components without incurring any visible image quality loss.
        luminance_quality = (config[MOZJPEG_LUMINANCE_QUALITY] || DEFAULT_QUALITY).to_i # Recommended default
        luminance_quality = MAX_QUALITY if luminance_quality > MAX_QUALITY

        cmd << "-quality #{luminance_quality},#{chrominance_quality}"

        # Perform optimization of entropy encoding parameters.
        # -optimize usually makes the JPEG file a little smaller,
        # but cjpeg runs somewhat slower and needs much more
        # memory.  Image quality and speed of decompression are
        # unaffected by -optimize.
        cmd << '-optimize'

        # Produce progressive JPEGs
        cmd << '-progressive'

        subsampling = (config[MOZJPEG_SUBSAMPLING] || DEFAULT_SUBSAMPLING).to_i
        cmd << "-sample #{subsampling}x#{subsampling}"

        # Reduces posterization in lower-quality JPEGs
        # https://calendar.perfplanet.com/2014/mozjpeg-3-0/
        quant_table = (config[MOZJPEG_QUANT_TABLE] || MS_SSIM).to_i
        cmd << "-quant-table #{quant_table}"

        # Makes images sharper, at the cost of increased file size
        # https://calendar.perfplanet.com/2014/mozjpeg-3-0/
        cmd << '-notrellis'

        cmd << %Q(-outfile "#{cache_img}")
        cmd << %Q("#{source_img}")

        Util::exec(cmd.join(' '))

        true
      end

      private

      # Name of the configuration attributes used to control
      # JPEG compression.
      MOZJPEG_LUMINANCE_QUALITY = :'mozjpeg-luminance-quality'
      MOZJPEG_CHROMINANCE_QUALITY = :'mozjpeg-chrominance-quality'
      MOZJPEG_QUANT_TABLE = :'mozjpeg-quant-table'
      MOZJPEG_SUBSAMPLING = :'mozjpeg-subsampling'

      # Default compression quality for images unless specified in the
      # configuration file under 'mozjpeg-quality'
      DEFAULT_QUALITY = 85

      # Default subsampling
      DEFAULT_SUBSAMPLING = 1

      # Quality limits
      MIN_QUALITY = 0
      MAX_QUALITY = 100

      # Quant table constants per the mozjpeg man page
      JPEG_ANNEX_K = 0
      FLAT = 1
      MS_SSIM = 2
      IMAGEMAGICK = 3
      PSNR_HVS = 4
      KLEIN_SILVERSTEIN_CARNEY = 5

    end

  end
end
