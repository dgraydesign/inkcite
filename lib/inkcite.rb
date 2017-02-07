require 'active_support/core_ext/kernel/reporting.rb'  # silence_warnings

# Need to silence warnings when we import these other gems as
# there are numerous messages produced as a result of circular
# dependencies and other problems within these gems, outside
# of my control.
silence_warnings do
  require 'csv'
  require 'erubis'
  require 'i18n'
  require 'image_optim'
  require 'set'
  require 'uri'
  require 'yaml'
  require 'yui/compressor'
end

require 'active_support/core_ext/hash/keys.rb'  # Symbolize keys!
require 'active_support/core_ext/module/delegation.rb'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_query'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/string/starts_ends_with'

require 'inkcite/version'
require 'inkcite/facade'
require 'inkcite/email'
require 'inkcite/util'
require 'inkcite/view'
require 'inkcite/minifier'
require 'inkcite/parser'
require 'inkcite/renderer'

module Inkcite

  def self.asset_path
    File.join(File.expand_path('../', File.dirname(__FILE__)), 'assets')
  end

  # Loads (and caches) the base64-encoded PNG data for the subtle background
  # texture that Inkcite installs on the <body> tag in development mode.
  def self.blueprint_image64
    @blueprint64 ||= begin
      blueprint_path = File.join(asset_path, 'blueprint.png')
      Base64.encode64(File.read(blueprint_path)).gsub(/[\r\f\n]/, '')
    end
  end

end

# Make sure only available locales are used. This will be the default in the
# future but we need this to silence a deprecation warning from 0.6.9
I18n.config.enforce_available_locales = true
