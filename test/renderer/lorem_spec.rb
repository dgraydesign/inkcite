describe Inkcite::Renderer::Lorem do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'produces placeholder text' do
    Inkcite::Renderer.render('{lorem}', @view).wont_equal('')
  end

  it 'triggers an error when included' do
    Inkcite::Renderer.render('{lorem}', @view)
    assert_error @view, 'Email contains Lorem Ipsum [markup={lorem}]'
  end

  it 'does not trigger an error when included and forced' do
    Inkcite::Renderer.render('{lorem force}', @view)
    assert_no_errors @view
  end

end
