module Inkcite
  class Email

    BROWSER_VERSION     = :'browser-version'
    CACHE_BUST          = :'cache-bust'
    IMAGE_HOST          = :'image-host'
    IMAGE_PLACEHOLDERS  = :'image-placeholders'
    OPTIMIZE_IMAGES     = :'optimize-images'
    TRACK_LINKS         = :'track-links'
    VIEW_IN_BROWSER_URL = :'view-in-browser-url'

    # Sub-directory where images are located.
    IMAGES = 'images'

    # Allowed environments.
    ENVIRONMENTS = [ :development, :preview, :production ].freeze

    # The path to the directory from which the email is being generated.
    # e.g. /projects/emails/holiday-mailing
    attr_reader :path

    def initialize path
      @path = path
    end

    def config
      Util.read_yml(File.join(path, 'config.yml'), :fail_if_not_exists => true)
    end

    def formats env=nil

      # Inkcite is always capable of producing an email version of
      # the project.
      f = [ :email ]

      f << :browser if config[BROWSER_VERSION] == true

      # Need to make sure a source.txt exists before we can include
      # it in the list of known formats.
      f << :text if File.exist?(project_file('source.txt'))

      f
    end

    def image_dir
      File.join(path, IMAGES)
    end

    def image_path file
      File.join(image_dir, file)
    end

    def meta key
      meta_data[key.to_sym]
    end

    # Optimizes this email's images if optimize-images is enabled
    # in the email configuration.
    def optimize_images
      Minifier.images(self, false) if optimize_images?
    end

    # Optimizes all of the images in this email.
    def optimize_images!
      Minifier.images(self, true)
    end

    def optimize_images?
      config[OPTIMIZE_IMAGES] == true
    end

    # Returns the directory that optimized, compressed images
    # have been saved to.
    def optimized_image_dir
      File.join(path, optimize_images?? Minifier::IMAGE_CACHE : IMAGES)
    end

    def project_file file
      File.join(path, file)
    end

    def set_meta key, value
      md = meta_data
      md[key.to_sym] = value
      File.open(File.join(path, meta_file_name), 'w+') { |f| f.write(md.to_yaml) }
      value
    end

    def upload
      require_relative 'uploader'
      Uploader.upload(self)
    end

    def upload!
      require_relative 'uploader'
      Uploader.upload!(self)
    end

    def versions
      [* self.config[:versions] || :default ].collect(&:to_sym)
    end

    def view environment, format, version=nil

      environment = environment.to_sym
      format = format.to_sym
      version = (version || versions.first).to_sym

      raise "Unknown environment \"#{environment}\" - must be one of #{ENVIRONMENTS.join(',')}" unless ENVIRONMENTS.include?(environment)

      _formats = formats(environment)
      raise "Unknown format \"#{format}\" - must be one of #{_formats.join(',')}" unless _formats.include?(format)
      raise "Unknown version: \"#{version}\" - must be one of #{versions.join(',')}" unless versions.include?(version)

      # Instantiate a new view of this email with the desired view and
      # format.
      View.new(self, environment, format, version)

    end

    # Returns an array of all possible Views (every combination of version
    # and format )of this email for the designated environment.
    def views environment, &block

      vs = []

      formats(environment).each do |format|
        versions.each do |version|
          ev = view(environment, format, version)
          yield(ev) if block_given?
          vs << ev
        end
      end

      vs
    end

    private

    # Name of the property controlling the meta data file name and
    # the default file name.
    META_FILE_NAME = :'meta-file'
    META_FILE      = '.inkcite'

    def meta_data
      Util.read_yml(File.join(path, meta_file_name))
    end

    def meta_file_name
      config[META_FILE_NAME] || META_FILE
    end

  end
end
