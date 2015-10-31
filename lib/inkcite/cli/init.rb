module Inkcite
  module Cli
    class Init

      def self.invoke path, opts

        full_init_path = File.expand_path(path)

        # Sanity check to make sure we're not writing over an existing
        # Inkcite project.
        abort "It appears that an Inkcite already exists in #{path}" if File.exists?(File.join(full_init_path, 'config.yml'))

        # Check to see if the user specified a --from path that is used to
        # clone an existing project rather than init a new one.
        from_path = opts[:from]

        # True if the designer wants the project empty/fresh rather than pre-populated
        # with the example/demonstration email content.
        is_empty = opts[:empty]

        # True if we're initializing a project from the built-in files.
        is_new = opts[:from].blank?
        if is_new

          # Use the default, bundled path if a from-path wasn't specified.
          # Verify the path exists
          from_path = File.join(Inkcite.asset_path, 'init')

        elsif is_empty
          abort "Can't initialize a project using --empty and --from at the same time"

        end

        init_image_path = File.join(path, Inkcite::Email::IMAGES)
        full_init_image_path = File.join(full_init_path, Inkcite::Email::IMAGES)

        # Create the images directory first because it's the deepest level
        # of the project structure.
        FileUtils.mkpath(full_init_image_path)
        puts "Created #{init_image_path}"

        # Verify that the source directory contains the config.yml file
        # signifying an existing Inkcite project.
        abort "Can't find #{from_path} or it isn't an existing Inkcite project" unless File.exists?(File.join(from_path, 'config.yml'))

        # Copy the main Inkcite project files
        Dir.glob(File.join(from_path, '*.{html,tsv,txt,yml}')).each do |from_file|
          FileUtils.cp(from_file, full_init_path)
          puts "Created #{File.join(path, from_file)}"
        end

        # If the example email is required, switch to the example root and
        # copy the files within over the existing files.
        unless is_empty
          from_path = File.join(Inkcite.asset_path, 'example')
          FileUtils.cp_r(File.join(from_path, '.'), full_init_path)
          puts 'Copied example email files'
        end

        # Check to see if there are images and copy those as well.
        from_path = File.join(from_path, Inkcite::Email::IMAGES)
        if File.exists?(from_path)
          FileUtils.cp_r(File.join(from_path, '.'), full_init_image_path)
          puts "Copied images to #{init_image_path}"
        end

      end

      private

      FILES = %w( config.yml source.html helpers.tsv source.txt )

    end
  end
end
