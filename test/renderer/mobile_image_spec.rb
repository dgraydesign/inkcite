require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::MobileImage do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'styles a span to show an image only on mobile' do
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300}{/mobile-img}', @view).must_equal('<span class="i01 img"></span>')
    @view.media_query.find_by_klass('i01').to_css.must_equal('span[class~="i01"] { background-image:url("images/inkcite-mobile.jpg");height:100px;width:300px }')
    @view.media_query.find_by_klass('img').to_css.must_equal('span[class~="img"] { display: block; background-position: center; background-size: cover; }')
  end

  it 'substitutes a placeholder for a missing image of sufficient size' do
    @view.config[Inkcite::Email::IMAGE_PLACEHOLDERS] = true
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300}{/mobile-img}', @view).must_equal('<span class="i01 img"></span>')
    @view.media_query.find_by_klass('i01').to_css.must_equal('span[class~="i01"] { background-image:url("http://placehold.it/300x100.jpg");height:100px;width:300px }')
  end

  it 'hides any images it wraps' do
    Inkcite::Renderer.render('{mobile-img src=inkcite-mobile.jpg height=100 width=300}{img src=inkcite.jpg height=50 width=100}{/mobile-img}', @view).must_equal('<span class="i01 img"><img border=0 class="hide" height=50 src="images/inkcite.jpg" style="display:block" width=100></span>')
  end

end
