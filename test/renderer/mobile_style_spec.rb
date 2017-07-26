describe Inkcite::Renderer::MobileStyle do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'requires a class name' do
    Inkcite::Renderer.render('{mobile-style}', @view).must_equal('')
    assert_error(@view, 'Declaring a mobile style requires a name attribute')
  end

  it 'requires a style declaration' do
    Inkcite::Renderer.render('{mobile-style name="slider"}', @view).must_equal('')
    assert_error(@view, 'Declaring a mobile style requires a style attribute', 'name=slider')
  end

  it 'raises a warning if the class name is not unique' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #0f0"}', @view).must_equal('')
    assert_error(@view, 'A mobile style was already defined with that class name', 'name=outlined', 'style=border: 1px solid #0f0')
  end

  it 'adds an inactive responsive style to the context' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    @view.media_query.find_by_klass('outlined').to_css.must_equal('.outlined { border: 1px solid #f00 }')
  end

  it 'can be applied to a responsive element' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    Inkcite::Renderer.render('{div mobile=outlined}{/div}', @view).must_equal('<div class="outlined"></div>')
  end

end
