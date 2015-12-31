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

            # Will hold the query parameters being passed to the placeholder service.
            # I didn't name these parameters - they're from the imgix.net API.
            query = {
                :txtsize => 18,
                :txttrack => 0,
                :w => width,
                :h => height,
                :fm => :jpg,
            }

            # Check to see if the designer specified FPO text for this placeholder -
            # otherwise default to the dimensions of the image.
            fpo = opt[:fpo]
            fpo = _src.dup if fpo.blank?
            fpo << "\n(#{width}×#{height})"
            query[:txt] = fpo

            # Check to see if the image has a background color.  If so, we'll use that
            # to set the background color of the placeholder.  We'll also pick a
            # contrasting color for the foreground text.
            bgcolor = detect_bgcolor(opt)
            unless none?(bgcolor)
              query[:bg] = bgcolor.gsub('#', '')
              query[:txtclr] = Util::contrasting_text_color(bgcolor).gsub('#', '')
            end

            # Replace the missing image with an imgix.net-powered placeholder using
            # the query parameters assembled above.
            # e.g. https://placeholdit.imgix.net/~text?txtsize=18&txt=left.jpg%0A%28155%C3%97155%29&w=155&h=155&fm=jpg&txttrack=0
            src = "//placeholdit.imgix.net/~text?#{query.to_query}"

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

      def mix_dimensions img, opt, ctx
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

