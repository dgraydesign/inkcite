require 'net/sftp'

module Inkcite
  class Uploader

    def self.upload email

      times = []

      [ 'source.html', 'source.tsv' ].each do |file|
        times << File.mtime(email.project_file(file)).to_i
      end

      local_images = email.image_dir
      if File.exists?(local_images)
        Dir.foreach(local_images) do |file|
          times << File.mtime(File.join(local_images, file)).to_i unless file.starts_with?('.')
        end
      end

      # Get the most recently updated file.
      last_update = times.max

      # Determine when the last upload was completed.
      last_upload = email.meta(:last_upload).to_i

      self.upload!(email) if last_update > last_upload

    end

    def self.upload! email

      # The preview version defines the configuration for the server to which
      # the files will be sftp'd.
      config = email.config[:sftp]

      # TODO: Verify SFTP configuration
      host     = config[:host]
      path     = config[:path]
      username = config[:username]
      password = config[:password]

      # This is the directory from which images will be uploaded.
      local_images = email.image_dir

      puts "Uploading to #{host} ..."

      # Get a local handle on the litmus configuration.
      Net::SFTP.start(host, username, :password => password) do |sftp|

        # Upload each version of the email.
        email.versions.each do |version|

          view = email.view(:preview, :browser, version)

          # Need to pass the upload path through the renderer to ensure
          # that embedded tags will be converted into data.
          remote_root = Inkcite::Renderer.render(path, view)

          # Recursively ensure that the full directory structure necessary for
          # the content and images is present.
          mkdir! sftp, remote_root

          # Check to see if there is a HTML version of this preview.  Some emails
          # do not have a hosted version and so it is not necessary to upload the
          # HTML version of the email - but this is a bad practice.
          file_name = view.file_name
          unless file_name.blank?
            sftp.file.open(File.join(remote_root, file_name), "w") { |f| view.write(f) }
          end

          # Upload the images to the remote directory.
          copy! sftp, local_images, remote_root

        end

      end

      # Timestamp to indicate we uploaded now
      email.set_meta :last_upload, Time.now.to_i

      true
    end

    private

    IMAGE_PATH = :'image-path'

    def self.copy! sftp, local, remote

      # Nothing to copy unless the local directory exists (e.g. some emails don't
      # have an images directory.)
      return unless File.exists?(local)

      Dir.foreach(local) do |file|
        next if file.starts_with?('.')

        local_file = File.join(local, file)
        unless File.directory?(local_file)

          remote_file = File.join(remote, file)

          next unless begin
            File.stat(local_file).mtime > Time.at(sftp.stat!(remote_file).mtime)
          rescue Net::SFTP::StatusException
            true # File doesn't exist, so assume it's changed.
          end

          puts "Uploading #{local_file} -> #{remote_file} ..."
          sftp.upload!(local_file, remote_file)

        end

      end
    end

    def self.mkdir! sftp, path

      _path = File::SEPARATOR

      path.split(File::SEPARATOR).each do |dir|

        # Add the child directory on to the path.
        _path = File.join(_path, dir)

        begin
          sftp.stat!(_path).directory?
        rescue Net::SFTP::StatusException
          begin
            puts "Creating directory: #{_path}"
            sftp.mkdir!(_path)
          rescue
            raise "Error creating #{_path}: #{$!}"
          end
        end
      end

    end

  end
end
