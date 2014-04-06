require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Td do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'can have empty parameters' do
    Inkcite::Renderer.render('{td}{/td}', @view).must_equal('<td></td>')
  end

  it 'has adjustable padding' do
    Inkcite::Renderer.render('{td padding=15}{/td}', @view).must_equal('<td style="padding:15px"></td>')
  end

  it 'will inherit padding from its parent table' do
    Inkcite::Renderer.render('{table padding=15}{td}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=15 cellspacing=0><tr><td style="padding:15px"></td></tr></table>')
  end

  it 'can inherit a font from the context' do
    Inkcite::Renderer.render('{td font=default}{/td}', @view).must_equal('<td style="color:#000000;font-size:15px;font-weight:normal;line-height:19px"></td>')
  end

  it 'can inherit a font from its parent table' do
    Inkcite::Renderer.render('{table font=default}{td}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr><td style="color:#000000;font-size:15px;font-weight:normal;line-height:19px"></td></tr></table>')
  end

  it 'can override a font inherited from its parent table' do
    Inkcite::Renderer.render('{table font=default}{td}{/td}{td font=large}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr><td style="color:#000000;font-size:15px;font-weight:normal;line-height:19px"></td><td style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></td></tr></table>')
  end

  it 'can have a custom font family' do
    Inkcite::Renderer.render('{td font-family="Comic Sans"}{/td}', @view).must_equal('<td style="font-family:Comic Sans"></td>')
  end

  it 'does not set the font family unnecessarily' do
    Inkcite::Renderer.render('{td font-family="{font-family}"}{/td}', @view).must_equal('<td></td>')
  end

  it 'can have a custom font size' do
    Inkcite::Renderer.render('{td font-size=18}{/td}', @view).must_equal('<td style="font-size:18px"></td>')
  end

  it 'can have a custom font weight' do
    Inkcite::Renderer.render('{td font-weight=bold}{/td}', @view).must_equal('<td style="font-weight:bold"></td>')
  end

  it 'can have a custom line height' do
    Inkcite::Renderer.render('{td line-height=15}{/td}', @view).must_equal('<td style="line-height:15px"></td>')
  end

end
