require 'webrick'
require 'rack'
require 'socket'

module Inkcite
  module Cli
    class Server

      def self.start email, opts

        # Port should always be an integer.
        port = opts[:port].to_i
        host = opts[:host]

        # Resolve local public IP for mobile device address
        ip = begin
          IPSocket.getaddress(Socket.gethostname)
        rescue
          nil
        end

        puts "Inkcite #{Inkcite::VERSION} is starting up ..."

        begin
          @server = ::WEBrick::HTTPServer.new({
              :BindAddress => host,
              :Port => port,
              :AccessLog => [],
              :Logger => WEBrick::Log.new(nil, 0)
          })
        rescue Errno::EADDRINUSE
          raise "== Port #{port} is unavailable. Either close the instance of Inkcite already running on #{port} or start this Inkcite instance on a new port with: --port=#{port+1}"
          exit(1)
        end

        # Listen to all of the things in order to properly
        # shutdown the server.
        %w(INT HUP TERM QUIT).each do |sig|
          if Signal.list[sig]
            Signal.trap(sig) do
              @server.shutdown
            end
          end
        end

        @server.mount "/", Rack::Handler::WEBrick, Inkcite::Cli::Server.new(email, opts)

        puts "Your email is being served at http://#{host}:#{port}"
        puts "Point your mobile device to http://#{ip}:#{port}" if ip

        @server.start

      end

      def initialize email, opts
        @email = email
        @opts = opts
      end

      def call env
        begin

          path = env[REQUEST_PATH]

          # If this request is for the root index page, render the email.  Otherwise
          # render the static asset.
          if path == REQUEST_ROOT

            # Check for and convert query string parameters to a symolized
            # key hash so the designer can override the environment, format
            # and version attributes during a given rendering.
            # Courtesy of http://stackoverflow.com/questions/21990997/how-do-i-create-a-hash-from-a-querystring-in-ruby
            params = CGI::parse(env[QUERY_STRING] || '')
            params = Hash[params.map { |key, values| [ key.to_sym, values[0] || true ] }].symbolize_keys

            # Allow the designer to specify both short- and long-form versions of
            # the (e)nvironment, (f)ormat and (v)ersion.  Otherwise, use the values
            # that Inkcite was started with.
            environment = Util.detect(params[:e], params[:environment], @opts[:environment])
            format = Util.detect(params[:f], params[:format], @opts[:format])
            version = Util.detect(params[:v], params[:view], @opts[:version])

            # Timestamp all of the messages from this rendering so it is clear which
            # messages are associated with this reload.
            ts = "[#{Time.now.strftime(DATEFORMAT)}]"

            puts ''
            puts "#{ts} Rendering your email [environment=#{environment}, format=#{format}, version=#{version || 'default'}]"

            view = @email.view(environment, format, version)

            html = view.render!

            unless view.errors.blank?
              error_count = view.errors.count
              puts "#{ts} #{error_count} error#{'s' if error_count > 1} or warning#{'s' if error_count > 1}:"
              puts "#{ts} - #{view.errors.join("\n#{ts} - ")}"
            end

            [200, {}, [html]]
          else
            Rack::File.new(Dir.pwd).call(env)

          end

        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
        end

      end

      private

      REQUEST_PATH = 'REQUEST_PATH'
      REQUEST_ROOT = '/'
      QUERY_STRING = 'QUERY_STRING'

      DATEFORMAT = '%Y-%m-%d %H:%M:%S'

    end
  end
end
