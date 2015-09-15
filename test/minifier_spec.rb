require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::View do

  before do
    @view = Inkcite::Email.new('test/project/').view(:production, :email)
    @view.is_enabled?(:minify).must_equal(true)
  end

  it "won't create compound words out of line breaks" do
    Inkcite::Minifier.html(%w(I am a multi-line string.), @view).must_equal('I am a multi-line string.')
  end

  it "removes trailing line-breaks" do
    Inkcite::Minifier.html(["This string has trailing line-breaks.\n\r\f"], @view).must_equal('This string has trailing line-breaks.')
  end

end
