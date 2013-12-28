require 'thor'
require_relative 'email'

module Inkcite
  class Cli < Thor

    desc 'build [options]', 'Build the static email assets for deployment'
    option :archive,
        :aliases => '-a',
        :desc => 'The name of the archive to compress final assets into'
    option :force,
        :aliases => '-f',
        :desc => 'Build even if there are errors (not recommended)',
        :type => :boolean
    def build
      require_relative 'cli/build'
      Inkcite::Cli::Build.invoke(email, {
          :archive => options['archive'],
          :force   => options['force']
      })
    end

    desc 'init NAME [options]', 'Initialize a new email project NAME'
    def init name
      require_relative 'cli/init'
      Inkcite::Cli::Init.invoke(name, options)
    end

    desc 'preview TO [options]', 'Send a preview of the email  recipient list: developer, internal or client'
    def preview to=:developer
      require_relative 'cli/preview'
      Inkcite::Cli::Preview.invoke(email, to, options)
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
      require_relative 'cli/server'

      Inkcite::Cli::Server.start(email, {
          :environment => environment,
          :format      => format,
          :host        => options['host'],
          :port        => options['port'],
          :version     => version
      })

    end

    desc 'test [options]', 'Tests (or re-tests) the email with Litmus'
    option :new,
      :aliases => '-n',
      :desc => 'Forces a new test to be created, otherwise will revision an existing test if present.',
      :type => :boolean
    def test
      require_relative 'cli/test'
      Inkcite::Cli::Test.invoke(email, options)
    end

    desc 'upload', 'Upload the preview version to the remote server'
    def upload
      email.upload!
    end

    private

    def environment
      options['environment'] || :development
    end

    def email
      Inkcite::Email.new(Dir.pwd)
    end

    def format
      options['format'] || :email
    end

    def version
      options['version']
    end

    def view
      email.view(environment, format, version)
    end

  end
end
