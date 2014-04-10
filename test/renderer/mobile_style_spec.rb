require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::MobileStyle do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'requires a class name' do
    Inkcite::Renderer.render('{mobile-style}', @view).must_equal('')
    @view.errors.must_include('Declaring a mobile style requires a name attribute (line 0)')
  end

  it 'requires a style declaration' do
    Inkcite::Renderer.render('{mobile-style name="slider"}', @view).must_equal('')
    @view.errors.must_include('Declaring a mobile style requires a style attribute (line 0) [name=slider]')
  end

  it 'raises a warning if the class name is not unique' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #0f0"}', @view).must_equal('')
    @view.errors.must_include('A mobile style was already defined with that class name (line 0) [name=outlined, style=border: 1px solid #0f0]')
  end

  it 'adds an inactive responsive style to the context' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    rule = @view.responsive_styles.find { |r| r.klass == 'outlined' && r.declarations == 'border: 1px solid #f00' && !r.active? }
    rule.nil?.must_equal(false)
    rule.to_css.must_equal('[class~="outlined"] { border: 1px solid #f00 }')
  end

  it 'can be applied to a responsive element' do
    Inkcite::Renderer.render('{mobile-style name="outlined" style="border: 1px solid #f00"}', @view).must_equal('')
    Inkcite::Renderer.render('{div mobile=outlined}{/div}', @view).must_equal('<div class="outlined"></div>')
  end

end
