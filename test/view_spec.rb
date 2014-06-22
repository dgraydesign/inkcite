require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::View do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'converts single and double quotes to unicode' do
    Inkcite::Renderer.fix_illegal_characters('“That’s what she said!”', @view).must_equal('&#8220;That&#8217;s what she said!&#8221;')
  end

end
