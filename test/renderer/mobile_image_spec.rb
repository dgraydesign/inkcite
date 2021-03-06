describe Inkcite::Renderer::MobileImage do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'styles a span to show an image only on mobile' do
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300}', @view).must_equal('<span class="i01 img"></span>')
    @view.media_query.find_by_klass('i01').to_css.must_equal('span.i01 { background-image:url("images/inkcite-mobile.jpg");height:100px;width:300px }')
    @view.media_query.find_by_klass('img').to_css.must_equal('span.img { display: block; background-position: center; background-size: cover; }')
  end

  it 'substitutes a placeholder for a missing image of sufficient size' do
    @view.config[Inkcite::Email::IMAGE_PLACEHOLDERS] = true
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300}', @view).must_equal('<span class="i01 img"></span>')
    @view.media_query.find_by_klass('i01').to_css.must_equal('span.i01 { background-image:url("http://placeholdit.imgix.net/~text?fm=jpg&h=100&txt=inkcite-mobile.jpg%0A%28300%C3%97100%29&txtsize=18&txttrack=0&w=300");height:100px;width:300px }')
  end

  it 'supports mobile margins' do
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300 margin-bottom=15 margin-left=15}', @view).must_equal('<span class="i01 img"></span>')
        @view.media_query.find_by_klass('i01').to_css.must_equal('span.i01 { background-image:url("images/inkcite-mobile.jpg");height:100px;margin-bottom:15px;margin-left:15px;width:300px }')
  end


end
