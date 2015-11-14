module Inkcite
  module Cli
    class Build

      def self.invoke email, opts

        errors = false

        # Don't allow production files to be built if there are errors.
        email.views(opts[:environment]) do |ev|

          ev.render!
          next if ev.errors.blank?

          puts "The #{ev.version} version (#{ev.format}) has #{ev.errors.size} errors:"
          puts " - #{ev.errors.join("\n - ")}"
          errors = true

        end

        abort('Fix errors or use --force to build') if errors && !opts[:force]

        # First, compile all assets to the build directory.
        build_to_dir email, opts

        # Compress the directory into an archive if so desired.
        archive = opts[:archive]
        build_archive(email, opts) unless archive.blank?

      end

      private

      # Configuration value controlling where the production files will
      # be created
      BUILD_PATH = :'build-path'

      def self.build_archive email, opts

        require 'zip'

        # This is the fully-qualified path to the .zip file.
        zip_file = File.expand_path(opts[:archive])
        puts "Archiving to #{zip_file} ..."

        # The Zip::File will try to update an existing archive so just blow the old
        # one away if it still exists.
        File.delete(zip_file) if File.exists?(zip_file)

        # The absolute path to the build directories
        build_html_to = build_path(email)
        build_images_to = build_images_path(email)

        Zip::File.open(zip_file, Zip::File::CREATE) do |zip|

          # Add the minified images to the .zip archive
          if File.exists?(build_images_to)
            Dir.foreach(build_images_to) do |img|
              img_path = File.join(build_images_to, img)
              zip.add(File.join(Inkcite::Email::IMAGES, img), img_path) unless File.directory?(img_path)
            end
          end

          Dir.foreach(build_html_to) do |file|
            file_path = File.join(build_html_to, file)
            zip.add(file, file_path)
          end

        end

        # Remove the build directory
        FileUtils.rm_rf(build_html_to)

      end

      def self.build_to_dir email, opts

        # The absolute path to the build directories
        build_html_to = build_path(email)
        build_images_to = build_images_path(email)

        puts "Building to #{build_html_to}"

        # Sanity check to ensure we're not building to the same
        # directory as we're working.
        if File.identical?(email.path, build_html_to)
          puts "Working path and build path can not be the same.  Change the '#{BUILD_PATH}' value in your config.yml."
          exit(1)
        end

        # Clear the existing build-to directory so we don't get any
        # lingering files from the last build.
        FileUtils.rm_rf build_html_to

        # Remove any existing images directory and then create a new one to
        # ensure the entire build path exists.
        FileUtils.mkpath build_images_to

        # Check to see if images should be optimized and if so, perform said
        # optimization on new or updated images.
        email.optimize_images

        # For each of the production views, build the HTML and links files.
        email.views(opts[:environment]) do |ev|

          File.open(File.join(build_html_to, ev.file_name), 'w') { |f| ev.write(f) }

          # Tracked link CSV
          File.open(File.join(build_html_to, ev.links_file_name), 'w') { |f| ev.write_links_csv(f) } if ev.track_links?

        end

        # Copy all of the source images into the build directory in preparation
        # for optimization
        build_images_from = email.optimized_image_dir
        FileUtils.cp_r(File.join(build_images_from, '.'), build_images_to) if File.exists?(build_images_from)

      end

      def self.build_path email
        File.expand_path email.config[BUILD_PATH] || 'build'
      end

      def self.build_images_path email
        File.join(build_path(email), Email::IMAGES)
      end

    end
  end
end
