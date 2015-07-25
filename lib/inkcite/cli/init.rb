module Inkcite
  module Cli
    class Init

      def self.invoke path, opts

        full_init_path = File.expand_path(path)

        # Sanity check to make sure we're not writing over an existing
        # Inkcite project.
        abort "It appears that an Inkcite already exists in #{path}" if File.exists?(File.join(full_init_path, 'config.yml'))

        init_image_path = File.join(path, Inkcite::Email::IMAGES)
        full_init_image_path = File.join(full_init_path, Inkcite::Email::IMAGES)

        # Create the images directory first because it's the deepest level
        # of the project structure.
        FileUtils.mkpath(full_init_image_path)

        puts "Created #{init_image_path}"

        # Check to see if the user specified a --from path that is used to
        # clone an existing project rather than init a new one.
        from_path = opts[:from]

        # True if we're initializing a project from the built-in files.
        is_new = opts[:from].blank?

        # Use the default, bundled path if a from-path wasn't specified.
        # Verify the path exists
        from_path = File.join(File.expand_path('../../..', File.dirname(__FILE__)), 'assets', 'init') if is_new

        # Verify that the source directory contains the config.yml file
        # signifying an existing Inkcite project.
        abort "Can't find #{from_path} or it isn't an existing Inkcite project" unless File.exists?(File.join(from_path, 'config.yml'))

        # Copy the main Inkcite project files
        FILES.each do |file|
          from_file = File.join(from_path, file)
          next unless File.exists?(from_file)
          FileUtils.cp(from_file, full_init_path)
          puts "Created #{File.join(path, file)}"
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
