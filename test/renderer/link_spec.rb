describe Inkcite::Renderer::Link do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'renders an HTML anchor tag with default styling and _blank targeting' do
    Inkcite::Renderer.render('{a id="blog" href="http://blog.inkceptional.com"}Our blog{/a}', @view).must_equal('<a href="http://blog.inkceptional.com" style="color:#0099cc;text-decoration:none" target=_blank>Our blog</a>')
  end

  it 'can be configured to tag all links' do
    @view.config[:'tag-links'] = "tag=inkcite|{id}"
    Inkcite::Renderer.render('{a id="litmus" href="http://litmus.com"}Test Emails Here{/a}', @view).must_equal('<a href="http://litmus.com?tag=inkcite|litmus" style="color:#0099cc;text-decoration:none" target=_blank>Test Emails Here</a>')
  end

  it 'can be configured to tag links to specific domains' do
    @view.config[:'tag-links'] = "tag=inkcite|{id}"
    @view.config[:'tag-links-domain'] = 'inkceptional.com'
    Inkcite::Renderer.render('{a id="blog" href="http://blog.inkceptional.com"}Our blog{/a}', @view).must_equal('<a href="http://blog.inkceptional.com?tag=inkcite|blog" style="color:#0099cc;text-decoration:none" target=_blank>Our blog</a>')
    Inkcite::Renderer.render('{a id="litmus" href="http://litmus.com"}Test Emails Here{/a}', @view).must_equal('<a href="http://litmus.com" style="color:#0099cc;text-decoration:none" target=_blank>Test Emails Here</a>')
  end

  it 'can be configured to tag links to at different domains' do
    @view.config[:'tag-links'] = { 'inkceptional.com' => 'tag=inkcite|{id}', 'blog.inkceptional.com' => 'campaign=blog'}
    Inkcite::Renderer.render('{a id="blog" href="http://blog.inkceptional.com"}Our blog{/a}', @view).must_equal('<a href="http://blog.inkceptional.com?campaign=blog" style="color:#0099cc;text-decoration:none" target=_blank>Our blog</a>')
    Inkcite::Renderer.render('{a id="litmus" href="http://litmus.com"}Test Emails Here{/a}', @view).must_equal('<a href="http://litmus.com" style="color:#0099cc;text-decoration:none" target=_blank>Test Emails Here</a>')
    Inkcite::Renderer.render('{a id="cp" href="http://client-preview.inkceptional.com"}Client Previews{/a}', @view).must_equal('<a href="http://client-preview.inkceptional.com?tag=inkcite|cp" style="color:#0099cc;text-decoration:none" target=_blank>Client Previews</a>')
  end

  it 'will not tag mailto: links' do
    @view.config[:'tag-links'] = "tag=inkcite|{id}"
    Inkcite::Renderer.render('{a id="contact-us" href="mailto:some.email@some.where"}Contact Us{/a}', @view).must_equal('<a href="mailto:some.email@some.where" style="color:#0099cc;text-decoration:none">Contact Us</a>')
  end

  it 'will not tag links that lead to an element in the email' do
    @view.config[:'tag-links'] = "tag=inkcite|{id}"
    Inkcite::Renderer.render('{a href="#news"}Latest News{/a}', @view).must_equal('<a href="#news" style="color:#0099cc;text-decoration:none">Latest News</a>')
  end

  it 'tags a reused link once and only once' do
    @view.config[:'tag-links'] = "tag=inkcite|{id}"
    @view.links_tsv['litmus'] = 'http://litmus.com'

    Inkcite::Renderer.render('{a id="litmus"}Test Emails Here{/a}{a id="litmus"}Also Here{/a}', @view).must_equal('<a href="http://litmus.com?tag=inkcite|litmus" style="color:#0099cc;text-decoration:none" target=_blank>Test Emails Here</a><a href="http://litmus.com?tag=inkcite|litmus" style="color:#0099cc;text-decoration:none" target=_blank>Also Here</a>')

  end

  it 'raises a warning and generates an ID if one is not present' do
    Inkcite::Renderer.render('{a href="http://inkceptional.com"}Click Here{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;text-decoration:none" target=_blank>Click Here</a>')
    assert_error @view, 'Link missing ID', 'href="http://inkceptional.com"'
  end

  it 'increments its automatically generated link ID' do
    Inkcite::Renderer.render('{a href="http://blog.inkceptional.com"}Our Blog{/a}', @view).must_equal('<a href="http://blog.inkceptional.com" style="color:#0099cc;text-decoration:none" target=_blank>Our Blog</a>')
    Inkcite::Renderer.render('{a href="http://inkceptional.com"}Inkceptional.com{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;text-decoration:none" target=_blank>Inkceptional.com</a>')
  end

  it 'can have a custom font color' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" color=#fc9}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#ffcc99;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'can inherit link color from a parent td' do
    Inkcite::Renderer.render('{td link=#0c3}{a id="order-now" href="http://inkceptional.com"}Order Now{/a}{/td}', @view).must_equal('<td><a href="http://inkceptional.com" style="color:#00cc33;text-decoration:none" target=_blank>Order Now</a></td>')
  end

  it 'can inherit link color from a parent table' do
    Inkcite::Renderer.render('{table link=#396}{td}{a id="order-now" href="http://inkceptional.com"}Order Now{/a}{/td}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr><td><a href="http://inkceptional.com" style="color:#339966;text-decoration:none" target=_blank>Order Now</a></td></tr></table>')
  end

  it 'can have a custom font family' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" font-family="Comic Sans"}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;font-family:Comic Sans;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'can have a custom font size' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" font-size=72}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;font-size:72px;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'can have a custom font weight' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" font-weight=700}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;font-weight:700;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'can have a custom line height' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" line-height=64}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;line-height:64px;text-decoration:none" target=_blank>Order Now</a>')
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" line-height=normal}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;line-height:normal;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'can inherit a font from the context' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" font=large}Order Now{/a}', @view).must_equal('<a href="http://inkceptional.com" style="color:#0099cc;font-family:serif;font-size:24px;font-weight:bold;line-height:24px;text-decoration:none" target=_blank>Order Now</a>')
  end

  it 'will wrap button-style responsive links in a div' do
    Inkcite::Renderer.render('{a id="order-now" href="http://inkceptional.com" mobile="button"}Order Now{/a}', @view).must_equal('<div><a class="button" href="http://inkceptional.com" style="color:#0099cc;text-decoration:none" target=_blank>Order Now</a></div>')
  end

  it 'detects invalid URLs' do
    Inkcite::Renderer.render(%Q({a id="oops" href="http://ink\nceptional.com"}), @view)
    assert_error(@view, 'Link href appears to be invalid', 'id=oops', "href=http://ink\nceptional.com")
  end

  it 'accepts invalid URLs if forced' do
    Inkcite::Renderer.render(%Q({a id="oops" href="http://ink\nceptional.com" force}), @view)
    assert_no_errors @view
  end

  it 'supports the block attribute' do
    Inkcite::Renderer.render(%Q({a id="order-now" href="http://inkceptional.com" block}), @view).must_equal(%Q(<a href="http://inkceptional.com" style="color:#0099cc;display:block;text-decoration:none" target=_blank>))
  end

end
