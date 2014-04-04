require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe 'Inkcite Link Rendering' do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'can render a div' do
    Inkcite::Renderer.render('{div}{/div}', @view).must_equal('<div></div>')
  end

  it 'can render a div with a custom font color' do
    Inkcite::Renderer.render('{div color=#f90}{/div}', @view).must_equal('<div style="color:#ff9900"></div>')
  end

  it 'can render a div with a custom font size' do
    Inkcite::Renderer.render('{div font-size=18}{/div}', @view).must_equal('<div style="font-size:18px"></div>')
  end

  it 'can render a div with a custom font weight' do
    Inkcite::Renderer.render('{div font-weight=bold}{/div}', @view).must_equal('<div style="font-weight:bold"></div>')
  end

  it 'can render a div with a custom line height' do
    Inkcite::Renderer.render('{div line-height=15}{/div}', @view).must_equal('<div style="line-height:15px"></div>')
  end

  it 'can render a div with a custom font family' do
    Inkcite::Renderer.render('{div font-family="Comic Sans"}{/div}', @view).must_equal('<div style="font-family:Comic Sans"></div>')
  end

  it 'can render a div that inherits font settings from the context' do
    Inkcite::Renderer.render('{div font=large}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the font size of a div with an inherited font' do
    Inkcite::Renderer.render('{div font=large font-size=8}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:8px;font-weight:bold;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large font-size=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the color of a div with an inherited font' do
    Inkcite::Renderer.render('{div font=large color=#00f}{/div}', @view).must_equal('<div style="color:#0000ff;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large color=none}{/div}', @view).must_equal('<div style="font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the font weight of a div with an inherited font' do
    Inkcite::Renderer.render('{div font=large font-weight=normal}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:normal;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large font-weight=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;line-height:24px"></div>')
  end

  it 'can override the line height of a div with an inherited font' do
    Inkcite::Renderer.render('{div font=large line-height=12}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:12px"></div>')
    Inkcite::Renderer.render('{div font=large line-height=auto}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:auto"></div>')
    Inkcite::Renderer.render('{div font=large line-height=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold"></div>')
  end

  it 'can apply a text shadow to a div' do
    Inkcite::Renderer.render('{div shadow=#99c}{/div}', @view).must_equal('<div style="text-shadow:0 1px 0 #9999cc"></div>')
    Inkcite::Renderer.render('{div shadow=#9c9 shadow-blur=2}{/div}', @view).must_equal('<div style="text-shadow:0 1px 2px #99cc99"></div>')
    Inkcite::Renderer.render('{div shadow=#c99 shadow-offset=-1}{/div}', @view).must_equal('<div style="text-shadow:0 -1px 0 #cc9999"></div>')
  end

  it 'can apply a background color to a div' do
    Inkcite::Renderer.render('{div bgcolor=#06c}{/div}', @view).must_equal('<div style="background-color:#0066cc"></div>')
  end

  it 'can make a div responsive' do
    Inkcite::Renderer.render('{div mobile=hide}{/div}', @view).must_equal('<div class="hide"></div>')
  end

end
