require 'net/sftp'
require 'stringio'

module Inkcite
  class Uploader

    def self.upload email

      times = []

      Dir.glob(File.join(email.path, '*.{html,tsv,txt,yml}')).each do |file|
        times << File.mtime(file).to_i
      end

      local_images = email.image_dir
      if File.exist?(local_images)
        Dir.foreach(local_images) do |file|
          times << File.mtime(File.join(local_images, file)).to_i unless file.starts_with?('.')
        end
      end

      # Get the most recently updated file.
      last_update = times.max

      # Determine when the last upload was completed.
      last_upload = email.meta(:last_upload).to_i

      self.do_upload(email, false) if last_update > last_upload

    end

    def self.upload! email
      self.do_upload(email, true)
    end

    private

    IMAGE_PATH = :'image-path'

    def self.copy! sftp, local, remote, force=true

      # Nothing to copy unless the local directory exists (e.g. some emails don't
      # have an images directory.)
      return unless File.exist?(local)

      Dir.foreach(local) do |file|
        next if file.starts_with?('.')

        local_file = File.join(local, file)
        unless File.directory?(local_file)

          remote_file = File.join(remote, file)

          unless force
            next unless begin
              File.stat(local_file).mtime > Time.at(sftp.stat!(remote_file).mtime)
            rescue Net::SFTP::StatusException
              true # File doesn't exist, so assume it's changed.
            end
          end

          puts "Uploading #{local_file} -> #{remote_file} ..."
          sftp.upload!(local_file, remote_file)

        end

      end
    end

    # Internal method responsive for doing the actual upload and
    # forcing (if necessary) the update of the graphics.
    def self.do_upload email, force

      # The preview version defines the configuration for the server to which
      # the files will be sftp'd.
      config = email.config[:sftp]
      if config.nil? || config.blank?
        puts "Unable to upload assets to CDN ('sftp:' section not found in config.yml)"
        return
      end

      # TODO: Verify SFTP configuration
      host = config[:host]
      path = config[:path]
      username = config[:username]
      password = config[:password]

      # Pre-optimize images before we upload them to the CDN.
      email.optimize_images

      # This is the directory from which images will be uploaded.
      # The email provides us with the correct directory based on
      # whether or not image optimization is enabled.
      local_images = email.optimized_image_dir

      # This is the last location of image upload.  If we're working
      # on multiple versions but the images all point to the same
      # location, it isn't necessary to re-upload images each time.
      last_remote_root = nil

      puts "Uploading to #{host} ..."

      begin

        # Get a local handle on the litmus configuration.
        Net::SFTP.start(host, username, :password => password) do |sftp|

          # Upload each version of the email.
          email.versions.each do |version|

            view = email.view(:preview, :email, version)

            # Need to pass the upload path through the renderer to ensure
            # that embedded tags will be converted into data.
            remote_root = Inkcite::Renderer.render(path, view)

            # Recursively ensure that the full directory structure necessary for
            # the content and images is present.
            mkdir! sftp, remote_root

            # Upload the images to the remote directory.  We use the last_remote_root
            # to ensure that we're not repeatedly uploading the same images over and
            # over when force is enabled -- but will re-upload images to distinct
            # remote roots.
            copy! sftp, local_images, remote_root, force && last_remote_root != remote_root
            last_remote_root = remote_root

            # Check to see if we're creating an in-browser version of the email.
            next unless email.formats.include?(:browser)

            browser_view = email.view(:preview, :browser, version)

            # Check to see if there is a HTML version of this preview.  Some emails
            # do not have a hosted version and so it is not necessary to upload the
            # HTML version of the email - but this is a bad practice.
            file_name = browser_view.file_name
            next if file_name.blank?

            remote_file_name = File.join(remote_root, file_name)
            puts "Uploading #{remote_file_name}"

            # We need to use StringIO to write the email to a buffer in order to upload
            # the email's content in binary so that its encoding is honored.  SFTP defaults
            # to ASCII-8bit in non-binary mode, so it was blowing up on UTF-8 special
            # characters (e.g. "Mäkinen").
            # http://stackoverflow.com/questions/9439289/netsftp-transfer-mode-binary-vs-text
            io = StringIO.new(browser_view.render!)
            sftp.upload!(io, remote_file_name)

          end

        end

      rescue SocketError => e
        abort <<-USAGE.strip_heredoc

          Oops! There was an unexpected error trying to upload to your
          CDN or image host:

            #{e.message}

          Please check that the sftp section of config.yml is correct:

            sftp:
              host: '#{host}'
              path: '#{path}'
              username: '#{username}'
              password: '#{password.gsub(/./, '*')}'

        USAGE

      end


      # Timestamp to indicate we uploaded now
      email.set_meta :last_upload, Time.now.to_i

      true
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
