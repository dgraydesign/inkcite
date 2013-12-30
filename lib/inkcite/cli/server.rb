require 'webrick'
require 'rack'

module Inkcite
  module Cli
    class Server

      def self.start email, opts

        # Port should always be an integer.
        port = opts[:port].to_i
        host = opts[:host]

        puts "== Inkcite is standing watch at http://#{host}:#{port}"
        puts "== Serving from #{Dir.pwd}"

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
            puts "Errors!\n - #{view.errors.join("\n - ")}"
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
