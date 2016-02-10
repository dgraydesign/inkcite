require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Redacted do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'renders redacted content' do
    Inkcite::Renderer.render('{redacted text="This Is Redacted Text."}', @view).must_equal('Xxxx Xx Xxxxxxxx Xxxx.')
  end

  it 'triggers an error when included' do
    Inkcite::Renderer.render('{redacted text="This is redacted text."}', @view)
    @view.errors.must_include('Email contains redacted content (line 0)')
  end

  it 'does not trigger an error when included and forced' do
    Inkcite::Renderer.render('{redacted force text="This is redacted text."}', @view)
    @view.errors.must_be_nil
  end

end