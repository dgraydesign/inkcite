

describe Inkcite::Animation do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'supports browser prefixing' do
    Inkcite::Animation.with_browser_prefixes("animation: video-frames 5s ease infinite", @view, { :separator => '; ' }).must_equal('animation: video-frames 5s ease infinite; -webkit-animation: video-frames 5s ease infinite; ')
  end

  it 'can instantiate an animation keyframe' do
    Inkcite::Animation::Keyframe.new(5, { :top => '-10px', :left => '22%' }).to_s.must_equal('  5%   { left:22%;top:-10px }')
  end

  it 'can add style to an animation keyframe' do
    keyframe = Inkcite::Animation::Keyframe.new(25)
    keyframe[:top] = '-15%'
    keyframe[:left] = '78px'
    keyframe.to_s.must_equal('  25%  { left:78px;top:-15% }')
  end

  it 'can prefix a style on a keyframe' do
    keyframe = Inkcite::Animation::Keyframe.new(33)
    keyframe.add_with_prefixes :transform, 'rotate(14deg)', @view
    keyframe.to_s.must_equal('  33%  { -webkit-transform:rotate(14deg);transform:rotate(14deg) }')
  end

  it 'can instantiate an animation and add keyframes' do
    anim = Inkcite::Animation::Keyframes.new('snowflake7', @view)
    anim << Inkcite::Animation::Keyframe.new(5, { :top => '-10px', :left => '22%' }).add_with_prefixes(:transform, 'rotate(14deg)', @view)
    anim.add_keyframe 25, { :top => '100%', :left => '18%' }
    anim.to_s.must_equal(%Q(@keyframes snowflake7 {\n  5%   { -webkit-transform:rotate(14deg);left:22%;top:-10px;transform:rotate(14deg) }\n  25%  { left:18%;top:100% }\n}\n@-webkit-keyframes snowflake7 {\n  5%   { -webkit-transform:rotate(14deg);left:22%;top:-10px;transform:rotate(14deg) }\n  25%  { left:18%;top:100% }\n}\n))
  end


end
