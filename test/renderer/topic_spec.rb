describe Inkcite::Renderer::Topic do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'requires a name' do
    Inkcite::Renderer.render('{topic}{topic name="Ipsum"}', @view)
    assert_error @view, 'Every topic must have a name'
  end

  it 'renders a list of topics' do
    html = Inkcite::Renderer.render('{topic-list} and more!{topic name="Lorem"}{topic name="Ipsum"}', @view)
    Inkcite::PostProcessor.run_all(html, @view).must_equal('Lorem, Ipsum and more!')
  end

  it 'supports topic priority' do
    html = Inkcite::Renderer.render('{topic-list} and more!{topic name="Lorem"}{topic name="Ipsum" priority=1}{topic name="Dolor"}', @view)
    Inkcite::PostProcessor.run_all(html, @view).must_equal('Ipsum, Lorem, Dolor and more!')
  end

  it 'warns if no topics are defined' do
    html = Inkcite::Renderer.render('{topic-list}', @view)
    Inkcite::PostProcessor.run_all(html, @view)
    assert_error @view, '{topic-list} included but no topics defined'
  end

end
