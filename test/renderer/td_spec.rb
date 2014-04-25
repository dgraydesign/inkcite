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

  it 'can have a specific vertical alignment' do
    Inkcite::Renderer.render('{td valign=bottom}{/td}', @view).must_equal('<td valign=bottom></td>')
  end

  it 'can inherit valign from its parent table' do
    Inkcite::Renderer.render('{table valign=top}{td}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr><td valign=top></td></tr></table>')
  end

  it 'will inherit mobile drop from its parent table' do
    Inkcite::Renderer.render('{table mobile="drop"}{td}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 class="fill"><tr><td class="drop"></td></tr></table>')
  end

  it 'can have a mobile behavior and a custom mobile style simultaneously' do
    Inkcite::Renderer.render('{td mobile="drop" mobile-style="border: 1px solid #f00"}{/td}', @view).must_equal('<td class="drop m1"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { border: 1px solid #f00 }')
  end

  it 'can have a background color' do
    Inkcite::Renderer.render('{td bgcolor=#f9c}{/td}', @view).must_equal('<td bgcolor=#ff99cc style="background-color:#ff99cc"></td>')
  end

  it 'can have a custom background color on mobile' do
    Inkcite::Renderer.render('{td mobile-bgcolor=#f09}{/td}', @view).must_equal('<td class="m1"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { background-color:#ff0099 }')
  end

  it 'can override background color on mobile' do
    Inkcite::Renderer.render('{td bgcolor=#f00 mobile-bgcolor=#00f}{/td}', @view).must_equal('<td bgcolor=#ff0000 class="m1" style="background-color:#ff0000"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { background-color:#0000ff !important }')
  end

  it 'can have a background image' do
    Inkcite::Renderer.render('{td background=floor.jpg background-position=bottom}{/td}', @view).must_equal('<td style="background:url(images/floor.jpg) bottom no-repeat"></td>')
  end

  it 'can have a background image on mobile' do
    Inkcite::Renderer.render('{td mobile-background-image=wall.jpg mobile-background-position=right mobile-background-repeat=repeat-y}{/td}', @view).must_equal('<td class="m1"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { background:url(images/wall.jpg) right repeat-y }')
  end

  it 'can override background image on mobile' do
    Inkcite::Renderer.render('{td background=floor.jpg background-position=bottom mobile-background-image=sky.jpg mobile-background-position=top}{/td}', @view).must_equal('<td class="m1" style="background:url(images/floor.jpg) bottom no-repeat"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { background:url(images/sky.jpg) top no-repeat !important }')
  end

  it 'inherits background position and repeat on mobile' do
    Inkcite::Renderer.render('{td background=floor.jpg background-position=bottom mobile-background-image=sky.jpg}{/td}', @view).must_equal('<td class="m1" style="background:url(images/floor.jpg) bottom no-repeat"></td>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('td[class~="m1"] { background:url(images/sky.jpg) bottom no-repeat !important }')
  end

end
