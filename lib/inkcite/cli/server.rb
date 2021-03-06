require 'guard'
require 'guard/commander'
require 'htmlbeautifier'
require 'rack'
require 'rack-livereload'
require 'webrick'

module Inkcite
  module Cli
    class Server

      def self.start email, opts

        Util.log "Inkcite #{Inkcite::VERSION} is starting up ..."
        Util.log 'Documentation available at http://inkcite.readme.io'

        # Read the hostname and port from the opts provided on the command
        # line - or inherit the default of localhost:4567
        port = opts[:port].to_i
        host = opts[:host]

        # Attempt to resolve the machine's public IP so we can display the
        # address for mobile devices.
        ip = begin
          IPSocket.getaddress(Socket.gethostname)
        rescue
          nil
        end

        fork do

          # Programmatically construct a Guard configuration file that
          # instructs it to monitor all of the HTML, TSV, YML and images
          # that can be used in the email project.
          guardfile = <<-EOF
            guard :livereload do
              watch(%r{^*.+\.(html|tsv|yml)})
              watch(%r{images/.+\.(gif|jpg|png)})
            end

            logger level: :error
          EOF

          # You can omit the call to Guard.setup, Guard.start will call Guard.setup
          # under the hood if Guard has not been setuped yet
          Guard.start :guardfile_contents => guardfile, :no_interactions => true

        end

        # Assemble the Rack app with the static content middleware and the
        # InkciteApp to server the email as the root index page.
        app = Rack::Builder.new do
          use Rack::LiveReload
          use Rack::Static, :urls => %w( /images/ ), :root => '.'
          use OptimizedImage, :email => email, :urls => %w( /images-optim/ ), :root => '.'
          run InkciteApp.new(email, opts)
        end

        Util.log ''
        Util.log "Your email is being served at http://#{host}:#{port}"
        Util.log "Point your mobile device to http://#{ip}:#{port}" if ip
        Util.log 'Press CTRL-C to exit server mode'
        Util.log ''

        begin

          # Start the server and disable WEBrick's verbose logging.
          Rack::Server.start({
                  :Host => host,
                  :Port => port,
                  :AccessLog => [],
                  :Logger => WEBrick::Log.new(nil, 0),
                  :app => app
              })
        rescue Errno::EADDRINUSE
          abort <<-USAGE.strip_heredoc

            Oops!  Inkcite can't start its preview server.  Port #{port} is
            unavailable. Either close the instance of Inkcite already running
            on that port or start this Inkcite instance on a new port with:

              inkcite server --port=#{port+1}

          USAGE
        end

      end

      private

      # Extends Rack::Static to provide dynamic image
      # minification on demand.  When an image is requested
      # from the images-optim directory, compression is
      # performed on the desired image if necessary and then
      # the optimized image is returned.
      class OptimizedImage < Rack::Static

        def initialize app, opts
          @email = opts[:email]
          super
        end

        def call env

          # e.g. images-optim/my-image.jpg
          path = env['PATH_INFO']

          # Minify the image if the source version in images/ is newer
          # or if the configuration file controlling optimization has
          # been updated since the last time the image was requested.
          Image::ImageMinifier.minify(@email, File.basename(path), false) if can_serve(path)

          # Let the super method handle the actual serving of the image.
          super

        end

      end

      class InkciteApp

        def initialize email, opts
          @email = email
          @opts = opts
        end

        def call env

          request = Rack::Request.new(env)

          # If this request is for the root index page, render the email.  Otherwise
          # render the static asset.
          return if request.path_info != REQUEST_ROOT

          response = Rack::Response.new
          response[Rack::CONTENT_TYPE] = 'text/html'

          begin

            # Allow the designer to specify both short- and long-form versions of
            # the (e)nvironment, (f)ormat and (v)ersion.  Otherwise, use the values
            # that Inkcite was started with.
            params = request.params
            environment = Util.detect(params['e'], params['environment'], @opts[:environment])
            format = Util.detect(params['f'], params['format'], @opts[:format])
            version = Util.detect(params['v'], params['version'], @opts[:version])

            Util.log "Rendering your email", :environment => environment, :format => format, :version => version || 'default'

            view = @email.view(environment, format, version)

            html = view.render!

            # If minification is disabled, then beautify the output to make it easier
            # for the designer to inspect the code being produced by Inkcite.
            html = HtmlBeautifier.beautify(html) unless view.is_enabled?(:minify)

            unless view.errors.blank?
              error_count = view.errors.count
              Util.log "#{error_count} error#{'s' if error_count > 1} or warning#{'s' if error_count > 1}:"
              view.errors.each { |e| Util.log(e) }
            end

            response.write html

          rescue Exception => e
            response.write "<html><head><title>Oops! There was a problem!</title></head><body style='padding: 30px; font-family: sans-serif;'>"
            response.write '<h2>Oops!</h2>'
            response.write "<p>There was a problem rendering your email: #{e.message}</p>"
            response.write "<pre>#{e.backtrace.join('<br>')}</pre>"
            response.write 'Please correct the problem and try reloading the page.'
            response.write '</body></html>'
          end

          response.finish

        end

      end

      REQUEST_ROOT = '/'

    end
  end
end
