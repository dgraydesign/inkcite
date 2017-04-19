describe Inkcite::Renderer::Social do

  before do
    @email = Inkcite::Email.new('test/project/')
    @view = @email.view(:development, :email)
  end

  it 'supports the noicon attribute' do

    # Need to delete the image if it exists because tests can run
    # in non-linear order
    twitter_icon = @email.image_path('twitter.png')
    File.delete(twitter_icon) if File.exist?(twitter_icon)
    Inkcite::Renderer.render('{twitter noicon href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter"}', @view).must_equal('<a href="https://twitter.com/share?url=http://inkcite.readme.io&text=Inkcite%20%23MakeEmailBetter" style="color:#0099cc;text-decoration:none" target=_blank>Tweet</a>')
    File.exist?(@view.email.image_path('twitter.png')).must_equal(false)
  end

  it 'supports sharing on Twitter' do
    Inkcite::Renderer.render('{twitter href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter"}', @view).must_equal('<a href="https://twitter.com/share?url=http://inkcite.readme.io&text=Inkcite%20%23MakeEmailBetter" style="color:#0099cc;font-size:15px;line-height:15px;text-decoration:none" target=_blank><img align=absmiddle alt="Twitter" border=0 height=15 id="OWATemporaryImageDivContainer1" src="images/twitter.png" style="display:inline;vertical-align:middle" width=19> Tweet</a>')
  end

  it 'copies the social sharing icons into the project' do
    Inkcite::Renderer.render('{facebook href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter"}', @view)
    File.exist?(@view.email.image_path('facebook.png')).must_equal(true)
  end

  it 'supports a configurable icon size' do
    Inkcite::Renderer.render('{twitter size=11 href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter"}', @view).must_equal('<a href="https://twitter.com/share?url=http://inkcite.readme.io&text=Inkcite%20%23MakeEmailBetter" style="color:#0099cc;font-size:11px;line-height:11px;text-decoration:none" target=_blank><img align=absmiddle alt="Twitter" border=0 height=11 id="OWATemporaryImageDivContainer1" src="images/twitter.png" style="display:inline;vertical-align:middle" width=14> Tweet</a>')
  end

  it 'supports sharing on Facebook' do
    Inkcite::Renderer.render('{facebook href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter"}', @view).must_equal('<a href="https://www.facebook.com/sharer/sharer.php?u=http://inkcite.readme.io&t=Inkcite%20%23MakeEmailBetter" style="color:#0099cc;font-size:15px;line-height:15px;text-decoration:none" target=_blank><img align=absmiddle alt="Facebook" border=0 height=15 id="OWATemporaryImageDivContainer1" src="images/facebook.png" style="display:inline;vertical-align:middle" width=15> Share</a>')
  end

  it 'supports sharing on Pintrest' do
    Inkcite::Renderer.render('{pintrest href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter" media="http://c1.staticflickr.com/9/8683/16620137238_71e78abd1d_n.jpg"}', @view).must_equal('<a href="https://www.pinterest.com/pin/create/button/?url=http://inkcite.readme.io&media=http://c1.staticflickr.com/9/8683/16620137238_71e78abd1d_n.jpg&description=Inkcite%20%23MakeEmailBetter" style="color:#CB2027;font-size:15px;line-height:15px;text-decoration:none" target=_blank><img align=absmiddle alt="Pintrest" border=0 height=15 id="OWATemporaryImageDivContainer1" src="images/pintrest.png" style="display:inline;vertical-align:middle" width=15> Pin it</a>')
  end

  it 'supports the nowrap attribute' do
    Inkcite::Renderer.render('{twitter href="http://inkcite.readme.io" text="Inkcite #MakeEmailBetter" nowrap}', @view).must_equal('<a href="https://twitter.com/share?url=http://inkcite.readme.io&text=Inkcite%20%23MakeEmailBetter" style="color:#0099cc;font-size:15px;line-height:15px;text-decoration:none;white-space:nowrap" target=_blank><img align=absmiddle alt="Twitter" border=0 height=15 id="OWATemporaryImageDivContainer1" src="images/twitter.png" style="display:inline;vertical-align:middle" width=19> Tweet</a>')
  end

  Minitest.after_run do
    email = Inkcite::Email.new('test/project/')

    %w( facebook.png pintrest.png twitter.png ).each do |img|
      image_path = email.image_path(img)
      File.delete(image_path) if File.exist?(image_path)
    end

  end

end
