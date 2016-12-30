describe Inkcite::Renderer::Element do

  it 'has configurable attributes' do
    Inkcite::Renderer::Element.new('a', :href => '"http://inkceptional.com"', :target => '"_blank"').to_s.must_equal('<a href="http://inkceptional.com" target="_blank">')
  end

  it 'has configurable styles which are rendered alphabetically' do
    e = Inkcite::Renderer::Element.new('div')
    e.style[:padding] = '5px'
    e.style[:border] = '1px solid #f00'
    e.to_s.must_equal('<div style="border:1px solid #f00;padding:5px">')
  end

  it 'has a unique, alphabetized list of classes' do
    e = Inkcite::Renderer::Element.new('div')
    e.classes << 'm1'
    e.classes << 'hide'
    e.to_s.must_equal('<div class="hide m1">')
    e.classes << 'm1' # Duplicate
    e.to_s.must_equal('<div class="hide m1">')
  end

  it 'can self-close' do
    Inkcite::Renderer::Element.new('br', :self_close => true).to_s.must_equal('<br />')
  end

end
