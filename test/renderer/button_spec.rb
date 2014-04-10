require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Button do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'inherits default settings from the context' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com"}Learn More{/button}', @view).must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"background-color:#0099cc;border-radius:5px\" width=175><tr>\n<td align=center style=\"line-height:auto;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#99ffff;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'can have a custom background color' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" bgcolor=#090}Learn More{/button}', @view).must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#009900 border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"background-color:#009900;border-radius:5px\" width=175><tr>\n<td align=center style=\"line-height:auto;padding:8px;text-shadow:0 -1px 0 #003d00\"><a href=\"http://inkceptional.com\" style=\"color:#99ff99;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'can have a custom bevel that is dynamically colored based on the background color' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" bevel=3}Learn More{/button}', @view).must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"background-color:#0099cc;border-bottom:3px solid #003d52;border-collapse:separate;border-radius:5px\" width=175><tr>\n<td align=center style=\"line-height:auto;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#99ffff;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

end
