require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Lorem do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'produces placeholder text' do
    Inkcite::Renderer.render('{lorem}', @view).wont_equal('')
  end

  it 'triggers an error when included' do
    Inkcite::Renderer.render('{lorem}', @view)
    @view.errors.must_include('Email contains Lorem Ipsum (line 0)')
  end

  it 'does not trigger an error when included and forced' do
    Inkcite::Renderer.render('{lorem force}', @view)
    @view.errors.must_be_nil
  end

end
