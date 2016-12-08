require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Button do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'inherits default settings from the context' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com"}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'can have a custom background color' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" bgcolor=#090}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#009900 border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'can have a custom bevel' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" bevel=3 bevel-color=#ff0000}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-bottom:3px solid #ff0000;border-collapse:separate;border-radius:5px\" width=175><tr>\n<td align=center style=\"padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'can have a custom font size' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" font-size=27}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"font-size:27px;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'has px line-height by default, if specified' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" font-size=27 line-height=56}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"font-size:27px;line-height:56px;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'accepts line-height specified in em units' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" font-size=27 line-height=2em}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"font-size:27px;line-height:2em;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'accepts normal line-height' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" font-size=27 line-height=normal}Learn More{/button}', @view).
        must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"font-size:27px;line-height:normal;padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

  it 'supports letter spacing' do
    Inkcite::Renderer.render('{button id="learn-more" href="http://inkceptional.com" letter-spacing=2px}Learn More{/button}', @view).
            must_equal("<a href=\"http://inkceptional.com\" style=\"text-decoration:none\" target=_blank><table align=center bgcolor=#0099cc border=0 cellpadding=8 cellspacing=0 class=\"fill\" style=\"border-radius:5px\" width=175><tr>\n<td align=center style=\"padding:8px;text-shadow:0 -1px 0 #003d52\"><a href=\"http://inkceptional.com\" style=\"color:#0099cc;letter-spacing:2px;text-decoration:none\" target=_blank>Learn More</a></td>\n</tr></table></a>")
  end

end
