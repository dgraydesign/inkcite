require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Email do

  before do
    @email = Inkcite::Email.new('test/project/')
  end

end
