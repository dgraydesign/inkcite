require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Footnote do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'requires text' do
    Inkcite::Renderer.render('({footnote symbol="†"})', @view)
    @view.errors.must_include('Footnote requires text attribute (line 0) [id=, symbol=†]')
  end

  it 'can have a custom symbol' do
    Inkcite::Renderer.render('({footnote symbol="†" text="See Blackmur, especially chapters 3 and 4, for an insightful analysis of this trend."})', @view).must_equal("(†)")
  end

  it 'assigns a numeric symbol if unspecified' do
    Inkcite::Renderer.render('({footnote text="EPA-estimated fuel economy."})', @view).must_equal("(1)")
  end

  it 'assigns an auto-incrementing symbol if multiple footnotes are provided' do
    Inkcite::Renderer.render('({footnote text="EPA-estimated fuel economy."})({footnote text="Actual mileage may vary."})', @view).must_equal("(1)(2)")
  end

  it 'can auto-increment with mixed symbols' do
    Inkcite::Renderer.render('({footnote text="EPA-estimated fuel economy."})({footnote symbol="†" text="See Blackmur, especially chapters 3 and 4, for an insightful analysis of this trend."})({footnote text="Actual mileage may vary."})', @view).must_equal("(1)(†)(2)")
  end

  it 'renders using the {footnotes} tag' do
    Inkcite::Renderer.render('yadda yadda({footnote text="EPA-estimated fuel economy."})<br><br>{footnotes}', @view).must_equal("yadda yadda(1)<br><br>1. EPA-estimated fuel economy.<br><br>")
  end

  it 'sorts symbols before numeric footnotes' do
    Inkcite::Renderer.render('({footnote text="EPA-estimated fuel economy."})({footnote symbol="†" text="See Blackmur, especially chapters 3 and 4, for an insightful analysis of this trend."})({footnote text="Actual mileage may vary."})<br><br>{footnotes}', @view).must_equal("(1)(†)(2)<br><br>†. See Blackmur, especially chapters 3 and 4, for an insightful analysis of this trend.<br><br>1. EPA-estimated fuel economy.<br><br>2. Actual mileage may vary.<br><br>")
  end

  it 'can have a reusable, readable ID assigned to it' do
    Inkcite::Renderer.render('({footnote id="epa" text="EPA-estimated fuel economy."})({footnote id="epa"})', @view).must_equal("(1)(1)")
  end

  it 'can have a custom template' do
    Inkcite::Renderer.render('({footnote text="EPA-estimated fuel economy."}) {footnotes tmpl="<p><sup>$symbol$</sup> $text$</p>"}', @view).must_equal("(1) <p><sup>1</sup> EPA-estimated fuel economy.</p>")
  end

end
