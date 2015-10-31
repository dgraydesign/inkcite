require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Span do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'can have empty parameters' do
    Inkcite::Renderer.render('{span}{/span}', @view).must_equal('<span></span>')
  end

  it 'can have a custom font color' do
    Inkcite::Renderer.render('{span color=#f90}{/span}', @view).must_equal('<span style="color:#ff9900"></span>')
  end

  it 'can have a custom font family' do
    Inkcite::Renderer.render('{span font-family="Comic Sans"}{/span}', @view).must_equal('<span style="font-family:Comic Sans"></span>')
  end

  it 'can have a custom font size' do
    Inkcite::Renderer.render('{span font-size=18}{/span}', @view).must_equal('<span style="font-size:18px"></span>')
  end

  it 'can have a custom font weight' do
    Inkcite::Renderer.render('{span font-weight=bold}{/span}', @view).must_equal('<span style="font-weight:bold"></span>')
  end

  it 'can have a custom line height' do
    Inkcite::Renderer.render('{span line-height=15}{/span}', @view).must_equal('<span style="line-height:15px"></span>')
  end

  it 'can inherit a font from the context' do
    Inkcite::Renderer.render('{span font=large}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></span>')
  end

  it 'can override the font size of an inherited font' do
    Inkcite::Renderer.render('{span font=large font-size=8}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:8px;font-weight:bold;line-height:24px"></span>')
    Inkcite::Renderer.render('{span font=large font-size=none}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-weight:bold;line-height:24px"></span>')
  end

  it 'can override the color of an inherited font' do
    Inkcite::Renderer.render('{span font=large color=#00f}{/span}', @view).must_equal('<span style="color:#0000ff;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></span>')
    Inkcite::Renderer.render('{span font=large color=none}{/span}', @view).must_equal('<span style="font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></span>')
  end

  it 'can override the font weight of an inherited font' do
    Inkcite::Renderer.render('{span font=large font-weight=normal}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;font-weight:normal;line-height:24px"></span>')
    Inkcite::Renderer.render('{span font=large font-weight=none}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;line-height:24px"></span>')
  end

  it 'can override the line height of an inherited font' do
    Inkcite::Renderer.render('{span font=large line-height=12}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:12px"></span>')
    Inkcite::Renderer.render('{span font=large line-height=normal}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:normal"></span>')
    Inkcite::Renderer.render('{span font=large line-height=none}{/span}', @view).must_equal('<span style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold"></span>')
  end

  it 'can have a text shadow' do
    Inkcite::Renderer.render('{span shadow=#99c}{/span}', @view).must_equal('<span style="text-shadow:0 1px 0 #9999cc"></span>')
    Inkcite::Renderer.render('{span shadow=#9c9 shadow-blur=2}{/span}', @view).must_equal('<span style="text-shadow:0 1px 2px #99cc99"></span>')
    Inkcite::Renderer.render('{span shadow=#c99 shadow-offset=-1}{/span}', @view).must_equal('<span style="text-shadow:0 -1px 0 #cc9999"></span>')
  end

  it 'can have a background color' do
    Inkcite::Renderer.render('{span bgcolor=#06c}{/span}', @view).must_equal('<span style="background-color:#0066cc"></span>')
  end

  it 'can be responsive' do
    Inkcite::Renderer.render('{span mobile=hide}{/span}', @view).must_equal('<span class="hide"></span>')
  end

  it 'can have custom letter spacing' do
    Inkcite::Renderer.render('{span letter-spacing=3}{/span}', @view).must_equal('<span style="letter-spacing:3px"></span>')
  end

  it 'can have a custom font size on mobile' do
    Inkcite::Renderer.render('{span font-size=15 mobile-font-size=20}{/span}', @view).must_equal('<span class="m1" style="font-size:15px"></span>')
    @view.media_query.find_by_klass('m1').declarations.must_match('font-size:20px !important')
  end

  it 'can have a custom line height on mobile' do
    Inkcite::Renderer.render('{span line-height=15 mobile-line-height=20}{/span}', @view).must_equal('<span class="m1" style="line-height:15px"></span>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('span[class~="m1"] { line-height:20px !important }')
  end

  it 'can inherit a custom font size on mobile from the context' do
    Inkcite::Renderer.render('{span font=responsive}{/span}', @view).must_equal('<span class="m1" style="font-size:20px"></span>')
    @view.media_query.find_by_klass('m1').declarations.must_match('font-size:40px')
  end

  it 'supports padding' do
    Inkcite::Renderer.render('{span padding=15}{/span}', @view).must_equal('<span style="padding:15px"></span>')
  end

end
