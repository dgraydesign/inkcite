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

  it "removes HTML comments" do
    Inkcite::Minifier.remove_comments(%Q(I am <!-- This is an HTML comment -->not commented<!-- This is another comment --> out), @view).must_equal('I am not commented out')
  end

  it "removes multi-line HTML comments" do
    Inkcite::Minifier.remove_comments(%Q(I am not <!-- This is a\n\nmulti-line HTML\ncomment -->commented out), @view).must_equal('I am not commented out')
  end

end
