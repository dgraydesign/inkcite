module Inkcite
  module Cli
    class Build

      def self.invoke email, opts

        errors = false

        # Don't allow production files to be built if there are errors.
        email.views(:production) do |ev|

          ev.render!

          if !ev.errors.blank?
            puts "The #{ev.version} version (#{ev.format}) has #{ev.errors.size} errors:"
            puts " - #{ev.errors.join("\n - ")}"
            errors = true
          end

        end

        abort("Fix errors or use -force to build") if errors && !opts[:force]

        # No archive? Build to files instead.
        if opts[:archive].blank?
          build_to_dir email, opts
        else
          build_to_archive email, opts
        end

      end

      private

      # Configuration value controlling where the production files will
      # be created
      BUILD_PATH = :'build-path'

      def self.build_to_archive email, opts

        require 'zip'

        # This is the fully-qualified path to the .zip file.
        zip_file = File.expand_path(opts[:archive])
        puts "== Archiving to #{zip_file} ..."

        # The Zip::File will try to update an existing archive so just blow the old
        # one away if it still exists.
        File.delete(zip_file) if File.exists?(zip_file)

        Zip::File.open(zip_file, Zip::File::CREATE) do |zip|

          email.each_image do |img|
            zip.add(File.join(Inkcite::Email::IMAGES, img), email.image_path(img))
          end

          email.views(:production) do |ev|

            zip.get_output_stream(ev.file_name) { |out| ev.write(out) }

            # Tracked link CSV
            zip.get_output_stream(ev.links_file_name) { |out| ev.write_links_csv(out) } if ev.track_links?

          end

        end

      end

      def self.build_to_dir email, opts

        # The absolute path to the build directory
        build_path = File.expand_path email.config[BUILD_PATH] || 'build'

        puts "== Building to #{build_path}"

        # Sanity check to ensure we're not building to the same
        # directory as we're working.
        if File.identical?(email.path, build_path)
          puts "Working path and build path can not be the same.  Change the '#{BUILD_PATH}' value in your config.yml."
          exit(1)
        end

        # Create the build path if it doesn't exist yet.
        FileUtils.mkpath build_path

        email.views(:production) do |ev|

          File.open(File.join(build_path, ev.file_name), 'w') { |f| ev.write(f) }

          # Tracked link CSV
          File.open(File.join(build_path, ev.links_file_name), 'w') { |f| ev.write_links_csv(f) } if ev.track_links?

        end

      end

    end
  end
end
