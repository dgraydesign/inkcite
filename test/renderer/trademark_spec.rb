describe Inkcite::Renderer::Trademark do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'warns if an id is not provided' do
    Inkcite::Renderer.render('{tm}', @view)
    assert_error @view, 'Missing id on trademark/registered symbol'
  end

  it 'renders a ™ symbol' do
    Inkcite::Renderer.render('{tm}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&trade;</sup>')
  end

  it 'renders a ™ symbol once' do
    Inkcite::Renderer.render('{tm id="pandora"}{tm id="pandora"}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&trade;</sup>')
  end

  it 'renders a ® symbol' do
    Inkcite::Renderer.render('{r}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&reg;</sup>')
  end

  it 'renders a ® symbol once' do
    Inkcite::Renderer.render('{r id="aha"}{r id="aha"}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&reg;</sup>')
  end

  it 'renders different ® symbols at the same time' do
    Inkcite::Renderer.render('{r id="aha"}{tm id="pandora"}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&reg;</sup><sup style="font-size:10px;line-height:10px;vertical-align:top">&trade;</sup>')
  end

  it 'allows superscripting to be disabled with the no-sup attribute' do
    Inkcite::Renderer.render('{r id="aha" no-sup}', @view).must_equal('&reg;')
  end

  it 'supports an associated footnote' do
    Inkcite::Renderer.render('{r id="leatherman" footnote="Leatherman is a trademark of Leatherman Tool Group, inc."}', @view).must_equal('<sup style="font-size:10px;line-height:10px;vertical-align:top">&reg;1</sup>')
  end

end
