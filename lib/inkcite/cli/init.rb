require 'fileutils'

module Inkcite
  class Cli::Init
    include Thor::Actions

    def self.invoke path, opts

      init_path = File.expand_path(path)

      # Sanity check to make sure we're not writing over an existing
      # Inkcite project.
      if File.exists?(File.join(init_path, 'config.yml'))
        abort "It appears that an Inkcite already exists in #{path}"
      end

      # Create the images directory first because it's the deepest level
      # of the project structure.
      FileUtils.mkpath(File.join(init_path, Inkcite::Email::IMAGES))

      puts "Created #{File.join(path, Inkcite::Email::IMAGES)}"

      asset_path = File.join(File.expand_path('../../..', File.dirname(__FILE__)), 'assets', 'init')

      FILES.each do |file|

        FileUtils.cp File.join(asset_path, file), init_path
        puts "Created #{File.join(path, file)}"

      end


    end

    private

    FILES = %w( config.yml source.html source.tsv source.txt )

  end
end
