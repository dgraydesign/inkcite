describe Inkcite::Renderer::Background do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'warns when an image is missing' do
    Inkcite::Renderer.render('{background src=missing.jpg}', @view)
    @view.errors.must_include('Missing image (line 0) [src=missing.jpg]')
  end

  it 'warns when an outlook-specific image is missing' do
    Inkcite::Renderer.render('{background outlook-src=also-missing.jpg}', @view)
    @view.errors.must_include('Missing image (line 0) [src=also-missing.jpg]')
  end

  it 'defaults to filling the available horizontal space' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports 100% width' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png width=100%}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports fill width' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png width=fill}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports an optional width in pixels' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png width=120}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=120><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports an optional height in pixels' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb height=92 width=120}{/background}', @view).must_equal('<table bgcolor=#7bceeb border=0 cellpadding=0 cellspacing=0 height=92 style="background:#7bceeb url(https://i.imgur.com/YJOX1PC.png)" width=120><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="height:92px;width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports an optional background color' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb width=120}{/background}', @view).must_equal('<table bgcolor=#7bceeb border=0 cellpadding=0 cellspacing=0 style="background:#7bceeb url(https://i.imgur.com/YJOX1PC.png)" width=120><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports the font attribute' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png font=large align=center}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px;text-align:center"></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports font-related attributes' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png font-size=18 line-height=27}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div style="font-size:18px;line-height:27px"></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
  end

  it 'supports a custom mobile background' do
    Inkcite::Renderer.render('{background src=https://i.imgur.com/YJOX1PC.png mobile-src="https://i.imgur.com/YJOX1PC-mobile.png" mobile-background-position="top" mobile-background-size="cover"}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 class="m1" style="background:url(https://i.imgur.com/YJOX1PC.png)" width=100%><tr><td><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
    @view.media_query.find_by_klass('m1').declaration_string.must_equal('background:url(https://i.imgur.com/YJOX1PC-mobile.png) top / cover no-repeat !important')
  end

  it 'supports mobile padding' do
    Inkcite::Renderer.render('{background src=background.jpg mobile-padding=15}{/background}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="background:url(images/background.jpg)" width=100%><tr><td class="m1"><!--[if mso]><v:rect fill="t" stroke="f" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="images/background.jpg" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:True"><![endif]--><div></div><!--[if mso]></v:textbox></v:rect><![endif]--></td></tr></table>')
    @view.media_query.find_by_klass('m1').declaration_string.must_equal('padding:15px')
  end

end
