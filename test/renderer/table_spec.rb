describe Inkcite::Renderer::Table do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'defaults border, cellpadding and cellspacing to zero' do
    Inkcite::Renderer.render('{table}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr></tr></table>')
  end

  it 'supports custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin-top:15px"><tr>')
    Inkcite::Renderer.render('{table margin-left=16}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin-left:16px"><tr>')
    Inkcite::Renderer.render('{table margin-bottom=17}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin-bottom:17px"><tr>')
    Inkcite::Renderer.render('{table margin-right=18}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin-right:18px"><tr>')
  end

  it 'supports multiple custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15 margin-left=6}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin-left:6px;Margin-top:15px"><tr>')
  end

  it 'supports a single all margin attribute' do
    Inkcite::Renderer.render('{table margin=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin:15px"><tr>')
  end

  it 'supports unified margins with directional override' do
    Inkcite::Renderer.render('{table margin=15 margin-left=8}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="Margin:15px;Margin-left:8px"><tr>')
  end

  it 'supports custom margins on mobile' do
    Inkcite::Renderer.render('{table mobile-margin=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 class="m1"><tr>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('table.m1 { margin:15px }')
  end

  it 'supports custom margin override on mobile' do
    Inkcite::Renderer.render('{table margin="12px 4px 0" mobile-margin=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 class="m1" style="Margin:12px 4px 0"><tr>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('table.m1 { margin:15px !important }')
  end

  it 'supports margin shortcuts on mobile' do
    Inkcite::Renderer.render('{table mobile-margin="15px 8px"}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 class="m1"><tr>')
    @view.media_query.find_by_klass('m1').to_css.must_equal('table.m1 { margin:15px 8px }')
  end

  it 'supports fluid-hybrid desktop and style' do
     Inkcite::Renderer.render('{table width=500 mobile=fluid}', @view).must_equal(%Q(<!--[if mso]><table border=0 cellpadding=0 cellspacing=0 width=500><tr><td><![endif]--><table border=0 cellpadding=0 cellspacing=0 style="max-width:500px" width=100%><tr>))
   end

  it 'carries table alignment into the Outlook wrap table in fluid-hybrid' do
     Inkcite::Renderer.render('{table align=center width=500 mobile=fluid}', @view).must_equal(%Q(<!--[if mso]><table align=center border=0 cellpadding=0 cellspacing=0 width=500><tr><td><![endif]--><table align=center border=0 cellpadding=0 cellspacing=0 style="max-width:500px" width=100%><tr>))
  end

  it 'supports fluid-drop desktop and style' do

    markup = ''
    markup << %Q({table font-size=25 bgcolor=#090 border="5px solid #f0f" padding=15 width=600 mobile="fluid-drop"})
    markup << %Q({td width=195 bgcolor=#009 color=#fff valign=top}left{/td})
    markup << %Q({td width=195 align=center}centered two-line{/td})
    markup << %Q({td width=195 bgcolor=#900 color=#fff align=right font-size=30}right<br>three<br>lines{/td})
    markup << %Q({/table})

    Inkcite::Renderer.render(markup, @view).must_equal(%Q(<!--[if mso]><table border=0 cellpadding=0 cellspacing=0 width=600><tr><td><![endif]--><table bgcolor=#009900 border=0 cellpadding=0 cellspacing=0 style="border:5px solid #f0f;max-width:600px" width=100%><tr><td style="font-size:0;text-align:center;vertical-align:middle"><!--[if mso]><table align=center border=0 cellpadding=0 cellspacing=0 width=100%><tr><![endif]--><!--[if mso]><td valign=top width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:top;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=left bgcolor=#000099 style="color:#ffffff;font-size:25px;padding:15px;text-align:left" valign=top>left</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]><td valign=middle width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:middle;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=center style="font-size:25px;padding:15px" valign=middle>centered two-line</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]><td valign=middle width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:middle;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=right bgcolor=#990000 style="color:#ffffff;font-size:30px;padding:15px" valign=middle>right<br>three<br>lines</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]></tr></table><![endif]--></td></tr></table><!--[if mso]></td></tr></table><![endif]-->))
  end

  it 'supports fluid-stack desktop and style' do

    markup = ''
    markup << %Q({table font-size=25 bgcolor=#090 border="5px solid #f0f" padding=15 width=600 mobile="fluid-stack"})
    markup << %Q({td width=195 bgcolor=#009 color=#fff valign=top}left{/td})
    markup << %Q({td width=195 align=center}centered two-line{/td})
    markup << %Q({td width=195 bgcolor=#900 color=#fff align=right font-size=30}right<br>three<br>lines{/td})
    markup << %Q({/table})

    Inkcite::Renderer.render(markup, @view).must_equal(%Q(<!--[if mso]><table border=0 cellpadding=0 cellspacing=0 width=600><tr><td><![endif]--><table bgcolor=#009900 border=0 cellpadding=0 cellspacing=0 style="border:5px solid #f0f;max-width:600px" width=100%><tr><td dir=rtl style="font-size:0;text-align:center;vertical-align:middle"><!--[if mso]><table align=center border=0 cellpadding=0 cellspacing=0 width=100%><tr><![endif]--><!--[if mso]><td valign=top width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:top;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=left bgcolor=#000099 style="color:#ffffff;font-size:25px;padding:15px;text-align:left" valign=top>left</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]><td valign=middle width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:middle;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=center style="font-size:25px;padding:15px" valign=middle>centered two-line</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]><td valign=middle width=195><![endif]--><div class="fill" style="display:inline-block;vertical-align:middle;width:195px"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td align=right bgcolor=#990000 style="color:#ffffff;font-size:30px;padding:15px" valign=middle>right<br>three<br>lines</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]></tr></table><![endif]--></td></tr></table><!--[if mso]></td></tr></table><![endif]-->))
  end

  it 'supports CSS animation' do
    Inkcite::Renderer.render('{table animation="video-frames 15s ease infinite"}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="-webkit-animation:video-frames 15s ease infinite;animation:video-frames 15s ease infinite"><tr>')
  end

  it 'supports the tr-transition attribute' do
    Inkcite::Renderer.render('{table tr-transition="all .5s cubic-bezier(0.075, 0.82, 0.165, 1)"}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr style="transition:all .5s cubic-bezier(0.075, 0.82, 0.165, 1)">')
  end

  it 'supports background gradients' do
    Inkcite::Renderer.render('{table bgcolor=#f00 bggradient=#00f}', @view).must_equal('<table bgcolor=#ff0000 border=0 cellpadding=0 cellspacing=0 style="background-image:radial-gradient(circle at center, #ff0000, #0000ff)"><tr>')
  end

end
