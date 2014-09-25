require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Email do

  before do
    @email = Inkcite::Email.new('test/project/')
  end

  it 'supports multi-line property declarations' do
    @email.properties[:multiline].must_equal("This\n    is a\n      multiline tag.")
    @email.properties[:"/multiline"].must_equal("This\n    ends the\n  multiline tag.")
  end

end
