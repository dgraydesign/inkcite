require 'thor'
require 'fileutils'

# For improved heredoc
# http://stackoverflow.com/a/9654275
require 'active_support/core_ext/string/strip'

module Inkcite
  module Cli
    class Base < Thor

      desc 'build [options]', 'Build the static email assets for deployment'
      option :archive,
          :aliases => '-a',
          :desc => 'The name of the archive to compress final assets into'
      option :environment,
          :aliases => '-e',
          :desc => 'The environment (development, preview or production) to build',
          :default => :production
      option :force,
          :aliases => '-f',
          :desc => 'Build even if there are errors (not recommended)',
          :type => :boolean

      def build
        require_relative 'build'
        Cli::Build.invoke(email, options)
      end

      desc 'init NAME [options]', 'Initialize a new email project in the NAME directory'
      option :'empty',
          :aliases => '-e',
          :desc => 'Prevents Inkcite from copying the example email files into the new project',
          :type => :boolean
      option :from,
          :aliases => '-f',
          :desc => 'Clones an existing Inkcite project (all images, helpers, partials, etc.) into the new one'

      def init name
        require_relative 'init'
        Cli::Init.invoke(name, options)
      end

      desc 'preview TO [options]', 'Send a preview of the email to a recipient list: developer, internal or client'
      option :version,
          :aliases => '-v',
          :desc => 'Preview a specific version of the email'
      option :also,
          :aliases => '-a',
          :desc => 'Add one or more (space-separated) recipients to this specific mailing',
          :type => :array
      option :'no-upload',
          :desc => 'Skip the asset upload, email the preview immediately',
          :type => :boolean
      def preview to=:developer
        require_relative 'preview'
        Cli::Preview.invoke(email, to, options)
      end

      desc 'scope [options]', 'Share this email using Litmus Scope (https://litmus.com/scope/)'
      option :version,
          :aliases => '-v',
          :desc => 'Scope a specific version of the email'
      def scope
        require_relative 'scope'
        Cli::Scope.invoke(email, options)
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
          :default => 4567,
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

      desc 'test [options]', 'Tests (or re-tests) the email with Litmus or Email on Acid'
      option :'no-upload',
          :desc => 'Skip the asset upload, test the email immediately',
          :type => :boolean
      option :version,
          :aliases => '-v',
          :desc => 'Test a specific version of the email'
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
