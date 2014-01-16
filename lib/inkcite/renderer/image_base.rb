module Inkcite
  module Renderer
    class ImageBase < Responsive

      protected

      # Display mode constants
      BLOCK   = 'block'
      DEFAULT = 'default'
      INLINE  = 'inline'

      def image_url _src, att, ctx

        src = _src

        # True if dimensions are missing.
        missing_dimensions = missing_dimensions?(att)

        # Fully-qualify the image path for this version of the email unless it
        # is already includes a full address.
        unless src.include?('://')

          # Verify that the image exists.
          if ctx.assert_image_exists(src)

            if missing_dimensions
              # TODO read the image dimensions from the file and auto-populate
              # the width and height fields.
            end

            # Convert the source (e.g. "cover.jpg") into a fully-qualified reference
            # to the image.  In development this may be images/cover.jpg but in the
            # other environments this would likely be a full URL to the image where it
            # is being hosted.
            src = ctx.image_url(src)

          else

            # As a convenience, replace missing images with placehold.it as long as they
            # meet the minimum dimensions.  No need to spam the design with tiny, tiny
            # placeholders.
            src = "http://placehold.it/#{att[:width]}x#{att[:height]}#{File.extname(src)}" if DIMENSIONS.all? { |dim| att[dim] > MINIMUM_DIMENSION_FOR_PLACEHOLDER }

          end

        end

        # Don't let an image go into production without dimensions.  Using the original
        # src so that we don't display the verbose qualified URL to the developer.
        ctx.error('Missing image dimensions', { :src => _src }) if missing_dimensions

        quote(src)
      end

      def klass_name src, ctx
        klass = "i%03d" % ctx.unique_id(:i)
      end

      def missing_dimensions? att
        DIMENSIONS.any? { |dim| att[dim] <= 0 }
      end

      def mix_background opt, sty

        # Background color of the image, if populated.
        bgcolor = opt[:bgcolor] || opt[BACKGROUND_COLOR]
        sty[BACKGROUND_COLOR] = hex(bgcolor) unless bgcolor.blank?

      end

      def mix_dimensions opt, att

        DIMENSIONS.each { |dim| att[dim] = opt[dim].to_i }

      end

      private

      # Both the height and width of the image must exceed this amount in order
      # to get a placehold.it automatically inserted.  Otherwise only an error
      # is raised for missing images.
      MINIMUM_DIMENSION_FOR_PLACEHOLDER = 25

    end
  end
end

