require_relative 'view/context'
require_relative 'view/media_query'
require_relative 'view/tag_stack'

module Inkcite
  class View

    # The base Email object this is a view of
    attr_reader :email

    # The rendered html or content available after render! has been called.
    attr_reader :content

    # One of :development, :preview or :production
    attr_reader :environment

    # The version of the email (e.g. :default)
    attr_reader :version

    # The format of the email (e.g. :email or :text)
    attr_reader :format

    # Manages the Responsive::Rules applied to this email view.
    attr_reader :media_query

    # Line number of the email file being processed
    attr_accessor :line

    # The configuration hash for the view
    attr_accessor :config

    # The array of error messages collected during rendering
    attr_accessor :errors

    # Will be populated with the css and js compressor objects
    # after first use.  Ensures we can reset the compressors
    # after a rendering is complete.
    attr_accessor :css_compressor
    attr_accessor :js_compressor

    def initialize email, environment, format, version, config
      @email = email
      @environment = environment
      @format = format
      @version = version

      # TODO Read this ourselves and run it through Erubis for better
      # a/b testing capabilities
      @config = config

      # Expose the version, format as a properties so that it can be resolved when
      # processing pathnames and such.  These need to be strings because they are
      # cloned during rendering.
      @config[:version] = version.to_s
      @config[:format] = format.to_s
      @config[FILE_NAME] = file_name

      # The MediaQuery object manages the responsive styles that are applied to
      # the email during rendering.
      @media_query = MediaQuery.new(self, 480)

      # Tracks the line number and is recorded when errors are encountered
      # while rendering said line.
      @line = 0

      # True if VML is used during the preparation of this email.
      @vml_used = false

    end

    def [] key
      key = key.to_sym

      # Look for configuration specific to the environment and then format.
      env_cfg = config[@environment] || EMPTY_HASH
      fmt_cfg = env_cfg[@format] || EMPTY_HASH

      # Not using || operator because the value can be legitimately false (e.g. minify
      # is disabled) so only a nil should trigger moving on to the next level up the
      # hierarchy.
      val = fmt_cfg[key]
      val = env_cfg[key] if val.nil?
      val = config[key] if val.nil?

      val
    end

    # Verifies that the provided image file (e.g. "banner.jpg") exists in the
    # project's image subdirectory.  If not, reports the missing image to the
    # developer (unless that is explicitly disabled).
    def assert_image_exists src

      # This is the full path to the image on the dev's harddrive.
      path = @email.image_path(src)
      exists = File.exists?(path)

      error('Missing image', { :src => src, :path => path }) if !exists

      exists
    end

    def browser?
      @format == :browser
    end

    def default?
      @version == :default
    end

    def development?
      @environment == :development
    end

    def email?
      @format == :email
    end

    # Records an error message on the currently processing line of the source.
    def error message, obj=nil

      message << " (line #{self.line.to_i})"
      unless obj.blank?
        message << ' ['
        message << obj.collect { |k, v| "#{k}=#{v}" }.join(', ')
        message << ']'
      end

      @errors ||= []
      @errors << message

      true
    end

    def footer
      @footer ||= []
    end

    def file_name ext=nil

      # Check to see if the file name has been configured.
      fn = self[FILE_NAME]
      if fn.blank?

        # Default naming based on the number of versions - only the format if there is
        # a single version or version and format when there are multiple versions.
        fn = if email.versions.length > 1
               '{version}-{format}'
             elsif text?
               'email'
             else
               '{format}'
             end

      end


      # Need to render the name to convert embedded tags to actual values.
      fn = Renderer.render(fn, self)

      # Sanity check to ensure there is an appropriate extension on the
      # file name.
      ext ||= (text?? TXT_EXTENSION : HTML_EXTENSION)
      fn << ext unless File.extname(fn) == ext

      fn
    end

    def image_url src

      src_url = ''

      # Prepend the image host onto the src if one is specified in the properties.
      # During local development, images are always expected in an images/ subdirectory.
      image_host = development?? "#{Email::IMAGES}/" : self[Email::IMAGE_HOST]
      src_url << image_host unless image_host.blank?

      # Add the source of the image.
      src_url << src

      # Cache-bust the image if the caller is expecting it to be there.
      src_url << "?#{Time.now.to_i}" if is_enabled?(Email::CACHE_BUST)

      # Transpose any embedded tags into actual values.
      Renderer.render(src_url, self)
    end

    # Tests if a configuration value has been enabled.  This assumes
    # it is disabled by default but that a value of true, 'true' or 1
    # for the value indicates it is enabled.
    def is_enabled? key
      val = self[key]
      !val.blank? && val != false && (val == true || val == true.to_s || val.to_i == 1)
    end

    # Tests if a configuration value has been disabled.  This assumes
    # it is enabled by default but that a value of false, 'false' or 0
    # will indicate it is disabled.
    def is_disabled? key
      val = self[key]
      !val.nil? && (val == false || val == false.to_s)
    end


    def links_file_name

      # There is nothing to return if trackable links aren't enabled.
      return nil unless track_links?

      fn = ''
      fn << "#{@version}-" if email.versions.length > 1
      fn << 'links.csv'

      # Need to render the name to convert embedded tags to actual values.
      Renderer.render(fn, self)

    end

    # Map of hrefs by their unique ID
    def links
      @links ||= {}
    end

    def meta key
      md = meta_data
      md.nil?? nil : md[key]
    end

    # Returns the opts for the parent matching the designated
    # tag, if any are presently open.
    def parent_opts tag
      tag_stack(tag).opts
    end

    def preview?
      @environment == :preview
    end

    def production?
      @environment == :production
    end

    def render!
      raise "Already rendered" unless @content.blank?

      source_file = 'source'
      source_file << (text?? TXT_EXTENSION : HTML_EXTENSION)

      # Read the original source which may include embedded Ruby.
      source = File.open(@email.project_file(source_file), 'r:windows-1252:utf-8').read

      # Run the content through Erubis
      filtered = Erubis::Eruby.new(source, :filename => source_file, :trim => false, :numbering => true).evaluate(Context.new(self))

      # Remove special characters that can cause rendering problems is
      # certain email clients.
      filtered.gsub!(/[‘’`]/, "'")
      filtered.gsub!(/[“”]/, '"')
      filtered.gsub!(/…/, '...')
      filtered.gsub!(/é/, '&eacute;')

      if text?

        filtered.gsub!(/[–—]/, '-')
        filtered.gsub!(/™/, '(tm)')
        filtered.gsub!(/®/, '(r)')

      else

        filtered.gsub!(/[–—]/, '&#8211;')
        filtered.gsub!(/\-\-/, '&#8211;')
        filtered.gsub!(/™/, '{sup}&trade;{/sup}')
        filtered.gsub!(/®/, '{sup}&reg;{/sup}')

      end

      # Filter each of the lines of text and push them onto the stack of lines
      # that we be written into the text or html file.
      lines = render_each(filtered)

      @content = if text?
        lines.join(NEW_LINE)

      else

        # Minify the content of the email.
        minified = Minifier.html(lines, self)

        # Some last-minute fixes before we assemble the wrapping content.
        prevent_ios_date_detection minified

        # Prepare a copy of the HTML for saving as the file.
        html = []
        html << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'

        # Resolve the HTML declaration for this email based on whether or not VML was used.
        html_declaration = '<html xmlns="http://www.w3.org/1999/xhtml"'
        html_declaration << ' xmlns:v="urn:schemas-microsoft-com:vml" lang="en" xml:lang="en"' if vml_used?
        html_declaration << '>'
        html << html_declaration

        html << '<head>'
        html << '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>'
        html << '<meta name="viewport" content="width=device-width"/>'

        html << "<title>#{self.subject}</title>"

        # Add external script sources.
        html += external_scripts

        # Add external styles
        html += external_styles

        html << '<style type="text/css">'
        html << inline_styles
        html << '</style>'
        html << '</head>'

        # Render the body statement and apply the email's background color to it.
        bgcolor = Renderer.hex(self[BACKGROUND])

        # Intentially not setting the link colors because those should be entirely
        # controlled by the styles and attributes of the links themselves.  By not
        # setting it, links created sans-helper should be visually distinct.
        html << Renderer.render("<body bgcolor=\"#{bgcolor}\" style=\"background-color: #{bgcolor}; width: 100% !important; margin: 0; padding: 0; -webkit-text-size-adjust: none; -ms-text-size-adjust: none;\">", self)

        html << minified

        # Append any arbitrary footer content
        html << inline_footer

        # Add inline scripts
        html << inline_scripts

        html << '</body></html>'

        # Remove all blank lines and assemble the wrapped content into a
        # a single string.
        html.select { |l| !l.blank? }.join(NEW_LINE)

      end

      # Ensure that all failsafes pass
      assert_failsafes

      # Verify that the tag stack is open which indicates all opened tags were
      # properly closed - e.g. all {table}s have matching {/table}s.
      #open_stack = @tag_stack && @tag_stack.select { |k, v| !v.empty? }
      #raise open_stack.inspect
      #error 'One or more {tags} may have been left open', { :open_stack => open_stack.collect(&:tag) } if open_stack

      @content
    end

    def rendered?
      !@content.blank?
    end

    def scripts
      @scripts ||= []
    end

    def set_meta key, value
      md = meta_data || {}
      md[key.to_sym] = value

      # Write the hash back to the email's meta data.
      @email.set_meta version, md

      value
    end

    def styles
      @styles ||= []
    end

    def subject
      @subject ||= Renderer.render((self[:title] || self[:subject] || 'Untitled Email'), self)
    end

    def tag_stack tag
      @tag_stack ||= Hash.new()
      @tag_stack[tag] ||= TagStack.new(tag, self)
    end

    # Sends this version of the email to Litmus for testing.
    def test!
      EmailTest.test! self
    end

    def text?
      @format == :text
    end

    def track_links?
      !self[Email::TRACK_LINKS].blank?
    end

    # Generates an incremental ID for the designated key.  The first time a
    # key is used, it will return a 1.  Subsequent requests for said key will
    # return 2, 3, etc.
    def unique_id key
      @unique_ids ||= Hash.new(0)
      @unique_ids[key] += 1
    end

    # Returns true if vml is enabled in this context.  This requires that the
    # context is for an email and that the VML property is enabled.
    def vml_enabled?
      email? && is_enabled?(:vml)
    end

    # Signifies that VML was used during the rendering and that
    def vml_used!
      raise 'VML was used but is not enabled' unless vml_enabled?
      @vml_used = true
    end

    def vml_used?
      @vml_used == true
    end

    def write out

      # Ensure that the version has been rendered fully
      render!

      # Fully-qualify the filename - e.g. public/project/issue/file_name and then write the
      # contents of the HTML to said file.
      out.write(@content)

      true
    end

    def write_links_csv out

      unless @links.blank?

        require 'csv'
        csv = CSV.new(out, :force_quotes => true)

        # Write each link to the CSV file.
        @links.keys.sort.each { |k| csv << [k, @links[k]] }
      end

      true
    end

    private

    ASSETS          = 'assets'
    BACKGROUND      = :'#background'
    FILE_SCHEME     = 'file'
    FILE_NAME       = :'file-name'
    HTML_EXTENSION  = '.html'
    LINKS_EXTENSION = '-links.csv'
    TXT_EXTENSION   = '.txt'
    NEW_LINE        = "\n"

    # Empty hash used when there is no environment or format-specific configuration
    EMPTY_HASH = {}

    # Name of the property holding the email field used to ensure that an unsubscribe has
    # been placed into emails.
    EMAIL_MERGE_TAG = :'email-merge-tag'

    def assert_in_browser msg
      raise msg if email? && !development?
    end

    def assert_failsafes

      passes = true

      failsafes = self[:failsafe] || self[:failsafes]
      unless failsafes.blank?

        incs = failsafes[:includes]
        [*incs].each do |i|
          unless @content.include?(i)
            error "Failsafe! Email does not include \"#{i}\""
            passes = false
          end
        end

        dnis = failsafes[:'does-not-include']
        [*dnis].each do |i|
          if @content.include?(i)
            error("Failsafe! Email must not include \"#{i}\"")
            passes = false
          end
        end

      end

      passes
    end

    def external_scripts
      html = []

      self.scripts.each do |js|
        if js.is_a?(URI::HTTP)
          assert_in_browser 'External scripts prohibited in emails'
          html << "<script src=\"#{js.to_s}\"></script>"
        end
      end

      html
    end

    def external_styles
      html = []

      self.styles.each do |css|
        if css.is_a?(URI::HTTP)
          assert_in_browser 'External stylesheets prohibited in emails'
          html << "<link href=\"#{css.to_s}\" rel=\"stylesheet\">"
        end
      end

      html
    end

    def from_uri uri
      if uri.is_a?(URI)
        if uri.scheme == FILE_SCHEME # e.g. file://facebook-like.js
          return Util.read(ASSETS, uri.host)
        else
          raise "Unsupported URI scheme: #{uri.to_s}"
        end
      end

      # Otherwise, return the string which is assumed to be already
      uri
    end

    def inline_footer
      html = ''
      self.footer.each { |f| html << Minifier.html(f.split("\n"), self) }
      html
    end

    def inline_scripts

      code = ''

      self.scripts.each do |js|
        next if js.is_a?(URI::HTTP)

        # Check to see if we've received a URI to a local asset file or if it's just javascript
        # to be included in the file.
        code << from_uri(js)

      end

      unless code.blank?
        assert_in_browser 'Scripts prohibited in emails'
        code = Minifier.js(code, self)
        code = "<script>\n#{code}\n</script>"
      end

      code
    end

    def inline_styles

      # This is the default font family for the email.
      font_family = self[Renderer::Base::FONT_FAMILY]

      reset = []

      if email?

        # Forces Hotmail to display emails at full width
        reset << '.ExternalClass, .ReadMsgBody { width:100%; }'

        # Forces Hotmail to display normal line spacing, here is more on that:
        # http://www.emailonacid.com/forum/viewthread/43/
        reset << '.ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div { line-height: 100%; }'

        # Not sure where I got this fix from.
        reset << '#outlook a { padding: 0; }'

        # Body text color for the New Yahoo.
        reset << '.yshortcuts, .yshortcuts a, .yshortcuts a:link,.yshortcuts a:visited, .yshortcuts a:hover, .yshortcuts a span { color: black; text-decoration: none !important; border-bottom: none !important; background: none !important; }'

        # Hides 'Today' ads in Yahoo!
        # https://litmus.com/blog/hiding-today-ads-yahoo?utm_source=newsletter&utm_medium=email&utm_campaign=april2012news */
        reset << 'XHTML-STRIPONREPLY { display:none; }'

        # This resolves the Outlook 07, 10, and Gmail td padding issue.  Here's more info:
        # http://www.ianhoar.com/2008/04/29/outlook-2007-borders-and-1px-padding-on-table-cells
        # http://www.campaignmonitor.com/blog/post/3392/1px-borders-padding-on-table-cells-in-outlook-07
        reset << 'table { border-spacing: 0; }'
        reset << 'table, td { border-collapse: collapse; }'

        # Ensure that telephone numbers are displayed using the same style as links.
        reset << "a[href^=tel] { color: #{self[Renderer::Base::LINK_COLOR]}; text-decoration:none;}"

      end

      # Reset the font on every cell to the default family.
      reset << "td { font-family: #{self[Renderer::Base::FONT_FAMILY]}; }"

      # Obviously VML-specific CSS needed only if VML was used in the issue.
      if vml_used?
        reset << 'v\:* { behavior: url(#default#VML); display: inline-block; }'
        reset << 'o\:* { behavior: url(#default#VML); display: inline-block; }'
      end

      # Responsive styles.
      reset += @media_query.to_a unless @media_query.blank?

      html = []

      # Append the minified CSS
      html << Minifier.css(reset.join(NEW_LINE), self)

      # Iterate through the list of files or in-line CSS and embed them into the HTML.
      self.styles.each do |css|
        next if css.is_a?(URI::HTTP)
        html << Minifier.css(from_uri(css), self)
      end

      html.join(NEW_LINE)
    end

    # Retrieves the version-specific meta data for this view.
    def meta_data
      @email.meta version
    end

    def prevent_ios_date_detection raw

      # Currently always performed in email but may want a configuration setting
      # that allows a creator to disable this default functionality.
      enabled = email?
      if enabled

        # Prevent dates (e.g. "February 28") from getting turned into unsightly blue
        # links on iOS by putting non-rendering whitespace within.
        # http://www.industrydive.com/blog/how-to-fix-email-marketing-for-iphone-ipad/
        Date::MONTHNAMES.select { |mon| !mon.blank? }.each do |mon|

          # Look for full month names (e.g. February) and add a zero-width space
          # afterwards which prevents iOS from detecting said date.
          raw.gsub!(/#{mon}/, "#{mon}#{Renderer::Base::ZERO_WIDTH_SPACE}")

        end

      end

      enabled
    end

    def render_each filtered

      lines = []

      filtered.split("\n").each do |line|

        # Increment the line number as we read the file.
        @line += 1

        begin
          line = Renderer.render(line, self)
        rescue Exception => e
          error e.message, { :trace => e.backtrace.first.gsub(/%2F/, '/') }
        end

        if text?

          # No additional splitting should be performed on the text version of the email.
          # Otherwise blank lines are lost.
          lines << line

        else

          # Sometimes the renderer inserts additional new-lines so we need to split them out
          # into individual lines if necessary.  Push all of the lines onto the issue's line array.
          lines += line.split(NEW_LINE)

        end

      end

      lines
    end

  end
end
