module Inkcite
  class Email

    CACHE_BUST          = :'cache-bust'
    IMAGE_HOST          = :'image-host'
    IMAGE_PLACEHOLDERS  = :'image-placeholders'
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
      Util.read_yml(File.join(path, 'config.yml'), true)
    end

    # Iterates through each of the original source images.
    def each_image &block
      dir = image_dir
      return false unless File.exists?(dir)

      Dir.foreach(dir) do |img|
        yield(img) unless File.directory?(File.join(dir, img))
      end

      true
    end

    def formats env

      f = [ :email, :browser ]

      # Need to make sure a source.txt exists before we can include
      # it in the list of known formats.
      f << :text if File.exists?(project_file('source.txt'))

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

    def properties

      opts = {
        :n => NEW_LINE
      }

      # Load the project's properties, which may include references to additional
      # properties in other directories.
      read_properties opts, 'helpers.tsv'

      # As a convenience pre-populate the month name of the email.
      mm = opts[:mm].to_i
      opts[:month] = Date::MONTHNAMES[mm] if mm > 0

      opts
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
      raise "Unknown format \"#{format}\" - must be one of #{FORMATS.join(',')}" unless FORMATS.include?(format)
      raise "Unknown version: \"#{version}\" - must be one of #{versions.join(',')}" unless versions.include?(version)

      opt = properties
      opt.merge!(self.config)

      # Instantiate a new view of this email with the desired view and
      # format.
      View.new(self, environment, format, version, opt)

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

    # Allowed formats.
    FORMATS = [ :browser, :email, :text ].freeze

    # Name of the property controlling the meta data file name and
    # the default file name.
    META_FILE_NAME = :'meta-file'
    META_FILE      = '.inkcite'

    COMMENT         = '//'
    NEW_LINE        = "\n"
    TAB             = "\t"
    CARRIAGE_RETURN = "\r"

    # Used for
    MULTILINE_START = "<<-START"
    MULTILINE_END = "END->>"
    TAB_TO_SPACE = '  '

    def meta_data
      Util.read_yml(File.join(path, meta_file_name), false)
    end

    def meta_file_name
      config[META_FILE_NAME] || META_FILE
    end

    def read_properties into, file

      fp = File.join(path, file)
      abort("Can't find #{file} in #{path} - are you sure this is an Inkcite project?") unless File.exists?(fp)

      # Consolidate line-breaks for simplicity
      raw = File.read(fp)
      raw.gsub!(/[\r\f\n]{1,}/, NEW_LINE)

      # Initial position of the
      multiline_starts_at = 0

      # Determine if there are any multiline declarations - those that are wrapped with
      # <<-START and END->> and reduce them to single line declarations.
      while (multiline_starts_at = raw.index(MULTILINE_START, multiline_starts_at))

        break unless (multiline_ends_at = raw.index(MULTILINE_END, multiline_starts_at))

        declaration = raw[(multiline_starts_at+MULTILINE_START.length)..multiline_ends_at - 1]
        declaration.strip!
        declaration.gsub!(/\t/, TAB_TO_SPACE)
        declaration.gsub!(/\n/, "\r")

        raw[multiline_starts_at..multiline_ends_at+MULTILINE_END.length - 1] = declaration

      end

      raw.split(NEW_LINE).each do |line|
        next if line.starts_with?(COMMENT)

        line.gsub!(/\r/, NEW_LINE)
        line.strip!

        key, open, close = line.split(TAB)
        next if key.blank?

        into[key.to_sym] = open.to_s.freeze

        # Prepend the key with a "/" and populate the closing tag.
        into["/#{key}".to_sym] = close.to_s.freeze

      end

      true
    end

  end
end
