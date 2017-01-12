describe Inkcite::Renderer::Image do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'warns when an image is missing' do
    Inkcite::Renderer.render('{img src=missing.jpg}', @view)
    @view.errors.must_include('Missing image (line 0) [src=missing.jpg]')
  end

  it 'warns when image dimesions are missing' do
    Inkcite::Renderer.render('{img src=inkcite.jpg}', @view)
    @view.errors.must_include('Missing image dimensions (line 0) [src=inkcite.jpg]')
  end

  it 'substitutes a placeholder for a missing image of sufficient size' do
    @view.config[Inkcite::Email::IMAGE_PLACEHOLDERS] = true
    Inkcite::Renderer.render('{img src=missing.jpg height=50 width=100}', @view).must_equal('<img border=0 height=50 src="http://placeholdit.imgix.net/~text?fm=jpg&h=50&txt=missing.jpg%0A%28100%C3%9750%29&txtsize=18&txttrack=0&w=100" style="display:block" width=100>')
  end

  it 'has configurable placeholder text' do
    @view.config[Inkcite::Email::IMAGE_PLACEHOLDERS] = true
    Inkcite::Renderer.render('{img src=missing.jpg height=50 width=100 fpo="F P O"}', @view).must_equal('<img border=0 height=50 src="http://placeholdit.imgix.net/~text?fm=jpg&h=50&txt=F+P+O%0A%28100%C3%9750%29&txtsize=18&txttrack=0&w=100" style="display:block" width=100>')
  end

  it 'does not substitute placeholders for small images' do
    @view.config[Inkcite::Email::IMAGE_PLACEHOLDERS] = true
    Inkcite::Renderer.render('{img src=missing.jpg height=5 width=15}', @view).must_equal('<img border=0 height=5 src="missing.jpg" style="display:block" width=15>')
  end

  it 'does not alter externally referenced images' do
    Inkcite::Renderer.render('{img src=://i.imgur.com/YJOX1PC.png height=5 width=15}', @view).must_equal('<img border=0 height=5 src="://i.imgur.com/YJOX1PC.png" style="display:block" width=15>')
  end

  it 'has configurable dimensions' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73}', @view).must_equal('<img border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
  end

  it 'has configurable background color' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 bgcolor=#f00}', @view).must_equal('<img border=0 height=73 src="images/inkcite.jpg" style="background-color:#ff0000;display:block" width=73>')
  end

  it 'has an inline display helper' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 display=inline}', @view).must_equal('<img align=absmiddle border=0 height=73 src="images/inkcite.jpg" style="display:inline;vertical-align:middle" width=73>')
  end

  it 'has no font styling unless specified' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 alt="Inkcite Avatar"}', @view).must_equal('<img alt="Inkcite Avatar" border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
  end

  it 'supports blank alt text' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 alt=""}', @view).must_equal('<img alt="" border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
  end

  it 'supports configurable font attributes' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 font="small" alt="Inkcite Avatar"}', @view).must_equal('<img alt="Inkcite Avatar" border=0 height=73 src="images/inkcite.jpg" style="color:#cccccc;display:block;font-size:11px" width=73>')
  end

  it 'has configurable font size' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 font-size=18 alt="Inkcite Avatar"}', @view).must_equal('<img alt="Inkcite Avatar" border=0 height=73 src="images/inkcite.jpg" style="display:block;font-size:18px" width=73>')
  end

  it 'supports font-size override' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 font="small" font-size=18 alt="Inkcite Avatar"}', @view).must_equal('<img alt="Inkcite Avatar" border=0 height=73 src="images/inkcite.jpg" style="color:#cccccc;display:block;font-size:18px" width=73>')
  end

  it 'ignores font attributes when alt text is not present' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 font=large}', @view).must_equal('<img border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 font-size=24}', @view).must_equal('<img border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
    Inkcite::Renderer.render('{img src=inkcite.jpg height=73 width=73 text-shadow=#f00}', @view).must_equal('<img border=0 height=73 src="images/inkcite.jpg" style="display:block" width=73>')
  end

  it 'includes a timestamp when cache-busting is enabled' do
    @view.config[:'cache-bust'] = true

    html = Inkcite::Renderer.render('{img src=inkcite.jpg}', @view)

    html[0,47].must_equal('<img border=0 height=0 src="images/inkcite.jpg?')
    html[47,10].must_match(/[0-9]{10,}/)
    html[57..-1].must_equal('" style="display:block" width=0>')
  end

  it 'can substitute a different image on mobile' do
    Inkcite::Renderer.render('{img src=inkcite.jpg mobile-src=inkcite-mobile.jpg height=75 width=125}', @view).must_equal('<img border=0 class="i01" height=75 src="images/inkcite.jpg" style="display:block" width=125>')
    @view.media_query.find_by_klass('i01').to_css.must_equal('img.i01 { content: url("images/inkcite-mobile.jpg") !important; }')
  end

  it 'supports fluid-hybrid desktop and style' do
    Inkcite::Renderer.render('{img src=inkcite.jpg height=200 width=325 mobile=fluid}', @view).must_equal('<img border=0 src="images/inkcite.jpg" style="display:block;height:auto;max-width:325px;width:100%" width=325>')
  end

  it 'supports multi-line alt text' do
    Inkcite::Renderer.render(%Q({img src=inkcite.jpg height=150 width=100 font=none alt="Multiple\nLine\nAlt\nText"}), @view).must_equal(%Q(<img alt="Multiple \nLine \nAlt \nText" border=0 height=150 src="images/inkcite.jpg" style="display:block;white-space:pre" width=100>))
  end

  it 'supports virtual (\n) multi-line alt text' do
    Inkcite::Renderer.render(%q({img src=inkcite.jpg height=150 width=100 font=none alt="Multiple\nLine\nAlt\nText"}), @view).must_equal(%Q(<img alt="Multiple \nLine \nAlt \nText" border=0 height=150 src="images/inkcite.jpg" style="display:block;white-space:pre" width=100>))
  end

  it 'supports multi-line alt text in production, too' do
    Inkcite::Renderer.render(%Q({img src=inkcite.jpg height=150 width=100 font=none alt="Multiple\nLine\nAlt\nText"}), Inkcite::Email.new('test/project/').view(:production, :email)).must_equal(%Q(<img alt="Multiple \nLine \nAlt \nText" border=0 height=150 src="http://production.imagehost.com/emails/myemail/inkcite.jpg" style="display:block;white-space:pre" width=100>))
    Inkcite::Renderer.render(%q({img src=inkcite.jpg height=150 width=100 font=none alt="Multiple\nLine\nAlt\nText"}), Inkcite::Email.new('test/project/').view(:production, :email)).must_equal(%Q(<img alt="Multiple \nLine \nAlt \nText" border=0 height=150 src="http://production.imagehost.com/emails/myemail/inkcite.jpg" style="display:block;white-space:pre" width=100>))
  end

  it 'removes HTML from alt text' do
    Inkcite::Renderer.render(%q({img src=inkcite.jpg height=150 width=100 alt="HTML <i>is not</i> allowed in alt text"}), @view).must_equal(%q(<img alt="HTML is not allowed in alt text" border=0 height=150 src="images/inkcite.jpg" style="display:block" width=100>))
  end

  it 'can show a different image in Outlook' do
    Inkcite::Renderer.render(%q({img src=animated.gif outlook-src=static.jpg height=150 width=100 alt="Don't repeat yourself"}), @view).must_equal(%q(<!--[if mso]><img alt="Don't repeat yourself" border=0 height=150 src="images/static.jpg" style="display:block" width=100><![endif]--><!--[if !mso]><!-- --><img alt="Don't repeat yourself" border=0 height=150 src="images/animated.gif" style="display:block" width=100><!--<![endif]-->))
  end

end
