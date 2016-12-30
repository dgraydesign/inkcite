describe Inkcite::Renderer do

  it 'converts #rgb to #rrggbb' do
    Inkcite::Renderer.hex('#rgb').must_equal('#rrggbb')
  end

  it 'converts a hash to an alphabetized parameter string' do
    Inkcite::Renderer.join_hash({ :src => 'logo.png', :height => 12, :alt => '"Company Logo"' }).must_equal('alt="Company Logo" height=12 src=logo.png')
  end

  it 'can render a CSS px value' do
    Inkcite::Renderer.px(5).must_equal('5px')
    Inkcite::Renderer.px(0).must_equal(0)
  end

  it 'can wrap a string in quotes' do
    Inkcite::Renderer.quote('Company Logo').must_equal('"Company Logo"')
  end

  it 'will not modify an expressionless string' do
    Inkcite::Renderer.render('Lorem ipsum dolor sit amet, consectetur adipiscing elit.', {}).must_equal('Lorem ipsum dolor sit amet, consectetur adipiscing elit.')
  end

end
