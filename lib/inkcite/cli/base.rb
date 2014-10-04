require 'thor'
require 'fileutils'

module Inkcite
  module Cli
    class Base < Thor

      desc 'build [options]', 'Build the static email assets for deployment'
      option :archive,
          :aliases => '-a',
          :desc => 'The name of the archive to compress final assets into'
      option :force,
          :aliases => '-f',
          :desc => 'Build even if there are errors (not recommended)',
          :type => :boolean

      def build
        require_relative 'build'
        Cli::Build.invoke(email, {
            :archive => options['archive'],
            :force => options['force']
        })
      end

      desc 'init NAME [options]', 'Initialize a new email project in the NAME directory'
      option :from,
          :aliases => '-f',
          :desc => 'Clones an existing Inkcite project into a new one'

      def init name
        require_relative 'init'
        Cli::Init.invoke(name, options)
      end

      desc 'preview TO [options]', 'Send a preview of the email  recipient list: developer, internal or client'

      def preview to=:developer
        require_relative 'preview'
        Cli::Preview.invoke(email, to, options)
      end

      desc 'server [options]', 'Start the preview server'
      option :environment,
          :aliases => '-e',
          :default => 'development',
          :desc => 'The environment Inkcite will run under'
      option :format,
          :aliases => '-f',
          :default => 'email',
          :desc => 'The format Inkcite will display - either email, browser or text'
      method_option :host,
          :type => :string,
          :aliases => '-h',
          :default => '0.0.0.0',
          :desc => 'The ip address Inkcite will bind to'
      method_option :port,
          :aliases => '-p',
          :default => '4567',
          :desc => 'The port Inkcite will listen on',
          :type => :numeric
      option :version,
          :aliases => '-v',
          :desc => 'Render a specific version of the email'

      def server
        require_relative 'server'

        Cli::Server.start(email, {
            :environment => environment,
            :format => format,
            :host => options['host'],
            :port => options['port'],
            :version => version
        })

      end

      desc 'test [options]', 'Tests (or re-tests) the email with Litmus'
      option :new,
          :aliases => '-n',
          :desc => 'Forces a new test to be created, otherwise will revision an existing test if present',
          :type => :boolean

      def test
        require_relative 'test'
        Cli::Test.invoke(email, options)
      end

      desc 'upload', 'Upload the preview version to your CDN or remote image server'
      option :force,
          :aliases => '-f',
          :desc => "Forces files to be uploaded regardless of whether or not they've changed",
          :type => :boolean
      def upload
        options[:force] ? email.upload! : email.upload
      end

      private

      # Resolves the desired environment (e.g. :development or :preview)
      # from Thor's commandline options.
      def environment
        options['environment'] || :development
      end

      def email
        Email.new(Dir.pwd)
      end

      # Resolves the desired format (e.g. :browser or :email) from Thor's
      # commandline options.
      def format
        options['format'] || :email
      end

      # Resolves the desired version (typically blank or :default) from
      # Thor's commandline options.
      def version
        options['version']
      end

      def view
        email.view(environment, format, version)
      end

    end
  end
end
