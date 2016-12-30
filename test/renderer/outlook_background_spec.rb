describe Inkcite::Renderer::OutlookBackground do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'warns when an image is missing' do
    Inkcite::Renderer.render('{outlook-bg src=missing.jpg}', @view)
    @view.errors.must_include('Missing image (line 0) [src=missing.jpg]')
  end

  it 'defaults to filling the available horizontal space' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'supports 100% width' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png width=100%}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'supports fill width' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png width=fill}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'supports an optional width in pixels' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png width=120}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'supports an optional height in pixels' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb height=92 width=120}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="height:92px;width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end


  it 'supports an optional background color' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb width=120}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'is automatically injected by the td helper' do
    Inkcite::Renderer.render('{td background=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb width=120 outlook-bg}{/td}', @view).must_equal(%Q(<td bgcolor=#7bceeb style="background:#7bceeb url(https://i.imgur.com/YJOX1PC.png)" width=120>\n<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->\n</td>))
  end

  it 'defaults to fill when injected by a td helper sans dimensions' do
    Inkcite::Renderer.render('{td background=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb outlook-bg}{/td}', @view).must_equal(%Q(<td bgcolor=#7bceeb style="background:#7bceeb url(https://i.imgur.com/YJOX1PC.png)">\n<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->\n</td>))
  end

  it 'inherits height from the parent td if present' do
    Inkcite::Renderer.render('{td background=https://i.imgur.com/YJOX1PC.png bgcolor=#7bceeb height=92 width=120 outlook-bg}{/td}', @view).must_equal(%Q(<td bgcolor=#7bceeb height=92 style="background:#7bceeb url(https://i.imgur.com/YJOX1PC.png)" width=120>\n<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="height:92px;width:120px" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill color="#7bceeb" src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0"><div><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->\n</td>))
  end

  it 'is ignored by the td helper if background is missing' do
    Inkcite::Renderer.render('{td bgcolor=#7bceeb outlook-bg}{/td}', @view).must_equal(%Q(<td bgcolor=#7bceeb></td>))
  end

  it 'supports the font attribute' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png font=large}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div style="color:#ff0000;font-family:serif;font-size:24px;font-weight:bold;line-height:24px"><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

  it 'supports font-related attributes' do
    Inkcite::Renderer.render('{outlook-bg src=https://i.imgur.com/YJOX1PC.png font-size=18 line-height=27}{/outlook-bg}', @view).must_equal('<!--[if gte mso 9]><v:rect fill="true" stroke="false" style="mso-width-percent:1000" xmlns:v="urn:schemas-microsoft-com:vml"><v:fill src="https://i.imgur.com/YJOX1PC.png" type="tile" /><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true"><div style="font-size:18px;line-height:27px"><![endif]--><!--[if gte mso 9]></div></v:textbox></v:rect><![endif]-->')
  end

end
