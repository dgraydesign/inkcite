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
        ip = IPSocket.getaddress(Socket.gethostname)

        puts "== Inkcite is starting up ..."

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

        puts "== Your email is being served at http://#{host}:#{port}"
        puts "== Point your mobile device to http://#{ip}:#{port}" if ip

        @server.start

      end

      def initialize email, opts
        @email = email
        @opts = opts
      end

      def call env

        path = env[REQUEST_PATH]

        # If this request is for the root index page, render the email.  Otherwise
        # render the static asset.
        if path == REQUEST_ROOT

          view = @email.view(@opts[:environment], @opts[:format], @opts[:version])

          html = view.render!

          unless view.errors.blank?
            error_count = view.errors.count

            puts ''
            puts "== Your email has #{error_count} error#{'s' if error_count > 1} or warning#{'s' if error_count > 1}:"
            puts " - #{view.errors.join("\n - ")}"
          end

          [200, {}, [html]]
        else
          Rack::File.new(Dir.pwd).call(env)

        end

      end

      private

      REQUEST_PATH = 'REQUEST_PATH'
      REQUEST_ROOT = '/'

    end
  end
end
