describe Inkcite::Renderer::MobileOnly do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'styles a div to show content only on mobile' do
    Inkcite::Renderer.render('{mobile-only}I will only appear on mobile{/mobile-only}', @view).must_equal('<!--[if !mso 9]><!--><div class="show" style="display:none;max-height:0;overflow:hidden">I will only appear on mobile</div><!--<![endif]-->')
    @view.media_query.find_by_klass('show').declarations.must_match('display: block !important; max-height: none !important;')
  end

  it 'supports inline as a boolean attribute' do
    Inkcite::Renderer.render('800-555-1212{mobile-only inline}&nbsp;&raquo;{/mobile-only}', @view).must_equal('800-555-1212<!--[if !mso 9]><!--><div class="show-inline" style="display:none;max-height:0;overflow:hidden">&nbsp;&raquo;</div><!--<![endif]-->')
    @view.media_query.find_by_klass('show-inline').declarations.must_match('display: inline !important; max-height: none !important;')
  end

  it 'does not support fonts or other container attributes' do
    Inkcite::Renderer.render('{mobile-only font=large}Fonts not supported{/mobile-only}', @view).must_equal('<!--[if !mso 9]><!--><div class="show" style="display:none;max-height:0;overflow:hidden">Fonts not supported</div><!--<![endif]-->')
  end

end
