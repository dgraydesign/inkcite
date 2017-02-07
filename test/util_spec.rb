describe Inkcite::Util do

  it 'can convert an HSL color to a hex color' do
    Inkcite::Util.hsl_to_color(78, 78, 78).must_equal('#d8f39b')
  end

  it 'can convert an HSL color to a hex color' do
    Inkcite::Util.hsl_to_color(128, 100, 50).must_equal('#00ff22')
  end

end
