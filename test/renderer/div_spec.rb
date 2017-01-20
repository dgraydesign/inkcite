describe Inkcite::Renderer::Div do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'can have empty parameters' do
    Inkcite::Renderer.render('{div}{/div}', @view).must_equal('<div></div>')
  end

  it 'can have a custom font color' do
    Inkcite::Renderer.render('{div color=#f90}{/div}', @view).must_equal('<div style="color:#ff9900"></div>')
  end

  it 'can have a custom font family' do
    Inkcite::Renderer.render('{div font-family="Comic Sans"}{/div}', @view).must_equal('<div style="font-family:Comic Sans"></div>')
  end

  it 'can have a custom font size' do
    Inkcite::Renderer.render('{div font-size=18}{/div}', @view).must_equal('<div style="font-size:18px"></div>')
  end

  it 'can have a custom font weight' do
    Inkcite::Renderer.render('{div font-weight=bold}{/div}', @view).must_equal('<div style="font-weight:bold"></div>')
  end

  it 'can have a custom line height' do
    Inkcite::Renderer.render('{div line-height=15}{/div}', @view).must_equal('<div style="line-height:15px"></div>')
  end

  it 'can inherit a font from the context' do
    Inkcite::Renderer.render('{div font=large}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the font size of an inherited font' do
    Inkcite::Renderer.render('{div font=large font-size=8}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:8px;font-weight:bold;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large font-size=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the color of an inherited font' do
    Inkcite::Renderer.render('{div font=large color=#00f}{/div}', @view).must_equal('<div style="color:#0000ff;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large color=none}{/div}', @view).must_equal('<div style="font-family:serif;font-size:24px;font-weight:bold;line-height:24px"></div>')
  end

  it 'can override the font weight of an inherited font' do
    Inkcite::Renderer.render('{div font=large font-weight=normal}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:normal;line-height:24px"></div>')
    Inkcite::Renderer.render('{div font=large font-weight=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;line-height:24px"></div>')
  end

  it 'can override the line height of an inherited font' do
    Inkcite::Renderer.render('{div font=large line-height=12}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:12px"></div>')
    Inkcite::Renderer.render('{div font=large line-height=normal}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:normal"></div>')
    Inkcite::Renderer.render('{div font=large line-height=none}{/div}', @view).must_equal('<div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold"></div>')
  end

  it 'can have a text shadow' do
    Inkcite::Renderer.render('{div shadow=#99c}{/div}', @view).must_equal('<div style="text-shadow:0 1px 0 #9999cc"></div>')
    Inkcite::Renderer.render('{div shadow=#9c9 shadow-blur=2}{/div}', @view).must_equal('<div style="text-shadow:0 1px 2px #99cc99"></div>')
    Inkcite::Renderer.render('{div shadow=#c99 shadow-offset=-1}{/div}', @view).must_equal('<div style="text-shadow:0 -1px 0 #cc9999"></div>')
  end

  it 'can have a background color' do
    Inkcite::Renderer.render('{div bgcolor=#06c}{/div}', @view).must_equal('<div style="background-color:#0066cc"></div>')
  end

  it 'can be responsive' do
    Inkcite::Renderer.render('{div mobile=hide}{/div}', @view).must_equal('<div class="hide"></div>')
  end

  it 'can have height in pixels' do
    Inkcite::Renderer.render('{div height=15}{/div}', @view).must_equal('<div style="height:15px"></div>')
  end

  it 'can have custom letter spacing' do
    Inkcite::Renderer.render('{div letter-spacing=3}{/div}', @view).must_equal('<div style="letter-spacing:3px"></div>')
  end

  it 'can have a custom font size on mobile' do
    Inkcite::Renderer.render('{div font-size=15 mobile-font-size=20}{/div}', @view).must_equal('<div class="m1" style="font-size:15px"></div>')
    @view.media_query.find_by_klass('m1').declarations.must_match('font-size:20px !important')
  end

  it 'can have a custom line height on mobile' do
    Inkcite::Renderer.render('{div line-height=15 mobile-line-height=20}{/div}', @view).must_equal('<div class="m1" style="line-height:15px"></div>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('div.m1 { line-height:20px !important }')
  end

  it 'can have a custom font color on mobile' do
    Inkcite::Renderer.render('{div color=#049 mobile-color=#f90}{/div}', @view).must_equal('<div class="m1" style="color:#004499"></div>')
    @view.media_query.find_by_klass('m1').declarations.must_match('color:#ff9900 !important')
  end

  it 'can inherit a custom font size on mobile from the context' do
    Inkcite::Renderer.render('{div font=responsive}{/div}', @view).must_equal('<div class="m1" style="font-size:20px"></div>')
    @view.media_query.find_by_klass('m1').declarations.must_match('font-size:40px')
  end

  it 'supports text alignment' do
    Inkcite::Renderer.render('{div align=right}{/div}', @view).must_equal('<div style="text-align:right"></div>')
  end

  it 'supports automatic background gradient' do
    Inkcite::Renderer.render('{div bgcolor=#f00 bggradient=#00f}{/div}', @view).must_equal('<div style="background-color:#ff0000;background-image:radial-gradient(circle at center, #ff0000, #0000ff)"></div>')
  end

  it 'supports custom background gradient' do
    Inkcite::Renderer.render('{div bggradient="radial-gradient(circle at center, #5b5f66, #1d1f21)"}{/div}', @view).must_equal('<div style="background-image:radial-gradient(circle at center, #5b5f66, #1d1f21)"></div>')
  end

  it 'supports a custom width on mobile' do
    Inkcite::Renderer.render('{div mobile-width=15}{/div}', @view).must_equal('<div class="m1"></div>')
    @view.media_query.find_by_klass('m1').declarations.must_match('width:15px')
  end

  it 'supports a custom override width on mobile' do
    Inkcite::Renderer.render('{div width=45 mobile-width=78}{/div}', @view).must_equal('<div class="m1" style="width:45px"></div>')
    @view.media_query.find_by_klass('m1').declarations.must_match('width:78px !important')
  end

end
