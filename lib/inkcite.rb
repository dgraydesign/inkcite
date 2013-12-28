require "inkcite/version"

module Inkcite
  class Base

    def self.asset_path
      File.expand_path('../../..', File.dirname(__FILE__))
    end

  end
end
