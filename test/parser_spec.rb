describe Inkcite::Parser do

  it 'can resolve name=value parameters' do
    Inkcite::Parser.parameters('border=1').must_equal({ :border => '1' })
  end

  it 'can resolve name-only boolean parameters' do
    Inkcite::Parser.parameters('selected').must_equal({ :selected => true })
  end

  it 'can resolve combinations of name=value and boolean parameters' do
    Inkcite::Parser.parameters('border=1 selected').must_equal({ :border => '1', :selected => true })
    Inkcite::Parser.parameters('selected border=1').must_equal({ :border => '1', :selected => true })
  end

  it 'can resolve parameters with dashes in the name' do
    Inkcite::Parser.parameters('border-radius=5').must_equal({ :'border-radius' => '5' })
  end

  it 'can resolve single word values sans double quotes' do
    Inkcite::Parser.parameters('color=#f90').must_equal({ :'color' => '#f90' })
  end

  it 'can resolve multi-word values wrapped in double quotes' do
    Inkcite::Parser.parameters('alt="Click Here!"').must_equal({ :alt => 'Click Here!' })
  end

  it 'can resolve complex, mixed parameters' do
    Inkcite::Parser.parameters('src="images/logo.png" height=50 width=100 alt="Generic Logo" mobile-style=hide').must_equal({ :src => 'images/logo.png', :height => '50', :width => '100', :alt => 'Generic Logo', :'mobile-style' => 'hide' })
  end

  it 'ignores malformed parameters' do
    Inkcite::Parser.parameters('a=1 b="2 c=3').must_equal({ :a => '1' })
  end

  it 'can identify an expression and replace it with a value' do

    results = Inkcite::Parser.each('{table border=1}') do |e|
      e.must_equal('table border=1')
      'OK'
    end

    results.must_equal('OK')
  end

  it 'can parse multiple expressions' do
    expressions = [ 'table border=1', 'img src=logo.png height=15' ]
    results = Inkcite::Parser.each('{table border=1}{img src=logo.png height=15}') do |e|
      expressions.wont_be_empty
      expressions -= [ e ]
      'OK'
    end
    expressions.must_be_empty
    results.must_equal('OKOK')
  end

  it 'can parse nested expression' do
    expressions = [ '#offwhite', 'table bgcolor=OK' ]
    results = Inkcite::Parser.each('{table bgcolor={#offwhite}}') do |e|
      expressions.wont_be_empty
      expressions -= [ e ]
      'OK'
    end
    expressions.must_be_empty
    results.must_equal('OK')
  end

  it 'does not loop forever' do
    begin
      Inkcite::Parser.each('{ok}') { |e| '{ok}' }
      false.must_equal(true) # Intentional, should never be thrown.
    rescue Exception => e
      e.message.must_equal("Infinite replacement detected: 1000 {ok}")
    end
  end

end
