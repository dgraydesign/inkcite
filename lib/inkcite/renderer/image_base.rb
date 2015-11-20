module Inkcite
  module Renderer
    class ImageBase < Responsive

      protected

      # Display mode constants
      BLOCK = 'block'
      DEFAULT = 'default'
      INLINE = 'inline'

      # For the given image source URL provided, returns either the fully-qualfied
      # path to the image (via View's image_url method) or returns a placeholder
      # if the image is missing.
      def image_url _src, opt, ctx

        src = _src

        # True if dimensions are missing.
        missing_dimensions = missing_dimensions?(opt)

        # Fully-qualify the image path for this version of the email unless it
        # is already includes a full address.
        unless Util::is_fully_qualified?(src)

          # Verify that the image exists.
          if ctx.assert_image_exists(src) || ctx.is_disabled?(Inkcite::Email::IMAGE_PLACEHOLDERS)

            if missing_dimensions
              # TODO read the image dimensions from the file and auto-populate
              # the width and height fields.
            end

            # Convert the source (e.g. "cover.jpg") into a fully-qualified reference
            # to the image.  In development this may be images/cover.jpg but in the
            # other environments this would likely be a full URL to the image where it
            # is being hosted.
            src = ctx.image_url(src)

          elsif DIMENSIONS.all? { |dim| opt[dim].to_i > MINIMUM_DIMENSION_FOR_PLACEHOLDER }

            width = opt[:width]
            height = opt[:height]

            # As a convenience, replace missing images with placehold.it as long as they
            # meet the minimum dimensions.  No need to spam the design with tiny, tiny
            # placeholders.
            src = "http://placehold.it/#{width}x#{height}.jpg"

            # Check to see if the image has a background color.  If so, we'll use that
            # to set the background color of the placeholder.
            bgcolor = detect_bgcolor(opt)
            src << "/#{bgcolor}".gsub('#', '') unless none?(bgcolor)

            # Check to see if the designer specified FPO text for this placeholder -
            # otherwise default to the dimensions of the image.
            fpo = opt[:fpo]
            fpo = _src.dup if fpo.blank?
            fpo << "\n(#{width}×#{height})"
            src << "?text=#{URI::encode(fpo)}"

          end

        end

        # Don't let an image go into production without dimensions.  Using the original
        # src so that we don't display the verbose qualified URL to the developer.
        ctx.error('Missing image dimensions', { :src => _src }) if missing_dimensions

        quote(src)
      end

      def klass_name src, ctx
        klass = "i%02d" % ctx.unique_id(:i)
      end

      def missing_dimensions? att
        DIMENSIONS.any? { |dim| att[dim].to_i <= 0 }
      end

      def mix_dimensions img, opt
        DIMENSIONS.each { |dim| img[dim] = opt[dim].to_i }
      end

      private

      # Both the height and width of the image must exceed this amount in order
      # to get a placehold.it automatically inserted.  Otherwise only an error
      # is raised for missing images.
      MINIMUM_DIMENSION_FOR_PLACEHOLDER = 25

    end
  end
end

