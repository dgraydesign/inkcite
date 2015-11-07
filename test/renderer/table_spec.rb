require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Table do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'defaults border, cellpadding and cellspacing to zero' do
    Inkcite::Renderer.render('{table}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr></tr></table>')
  end

  it 'supports custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-top:15px"><tr>')
    Inkcite::Renderer.render('{table margin-left=16}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-left:16px"><tr>')
    Inkcite::Renderer.render('{table margin-bottom=17}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:17px"><tr>')
    Inkcite::Renderer.render('{table margin-right=18}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-right:18px"><tr>')
  end

  it 'supports multiple custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15 margin-left=6}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-left:6px;margin-top:15px"><tr>')
  end

  it 'supports a single all margin attribute' do
    Inkcite::Renderer.render('{table margin=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:15px;margin-left:15px;margin-right:15px;margin-top:15px"><tr>')
  end

  it 'supports unified margins with directional override' do
    Inkcite::Renderer.render('{table margin=15 margin-left=8}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:15px;margin-left:8px;margin-right:15px;margin-top:15px"><tr>')
  end

  it 'supports fluid-hybrid desktop and style' do
     Inkcite::Renderer.render('{table width=500 mobile=fluid}', @view).must_equal(%Q(<!--[if mso]><table border=0 cellpadding=0 cellspacing=0 width=500><tr><td><![endif]--><table border=0 cellpadding=0 cellspacing=0 style="max-width:500px" width=100%><tr>))
   end

  it 'carries table alignment into the Outlook wrap table in fluid-hybrid' do
     Inkcite::Renderer.render('{table align=center width=500 mobile=fluid}', @view).must_equal(%Q(<!--[if mso]><table align=center border=0 cellpadding=0 cellspacing=0 width=500><tr><td><![endif]--><table align=center border=0 cellpadding=0 cellspacing=0 style="max-width:500px" width=100%><tr>))
  end

  it 'supports fluid-drop desktop and style' do

    markup = ''
    markup << %Q({table font-size=25 bgcolor=#090 border="5px solid #f0f" padding=15 width=600 mobile="fluid-drop" valign=top})
    markup << %Q({td width=295 bgcolor=#009 color=#fff}left{/td})
    markup << %Q({td width=295 bgcolor=#900 color=#fff font-size=30}right<br>and<br>tall{/td})
    markup << %Q({/table})

    Inkcite::Renderer.render(markup, @view).must_equal(%Q(<!--[if mso]><table border=0 cellpadding=0 cellspacing=0 width=600><tr><td><![endif]--><table bgcolor=#009900 border=0 cellpadding=0 cellspacing=0 style=\"border:5px solid #f0f;max-width:600px\" width=100%><tr><td style=\"font-size:0;text-align:center;vertical-align:top\"><!--[if mso]><table align=center border=0 cellpadding=0 cellspacing=0 width=100%><tr><![endif]--><!--[if mso]><td valign=top width=295><![endif]--><div class=\"fill\" style=\"display:inline-block;vertical-align:top;width:295px\"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td bgcolor=#000099 style=\"color:#ffffff;font-size:25px;padding:15px\" valign=top>left</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]><td valign=top width=295><![endif]--><div class=\"fill\" style=\"display:inline-block;vertical-align:top;width:295px\"><table border=0 cellpadding=15 cellspacing=0 width=100%><tr><td bgcolor=#990000 style=\"color:#ffffff;font-size:30px;padding:15px\" valign=top>right<br>and<br>tall</td></tr></table></div><!--[if mso]></td><![endif]--><!--[if mso]></tr></table><![endif]--></td></tr></table><!--[if mso]></td></tr></table><![endif]-->))
  end

end
