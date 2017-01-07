

describe Inkcite::Animation do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'supports browser prefixing' do
    Inkcite::Renderer::Style.new(nil, @view, { :animation => 'video-frames 5s ease infinite' }).to_s.must_equal('-webkit-animation:video-frames 5s ease infinite;animation:video-frames 5s ease infinite')
  end

  it 'supports browser prefixing specific items only' do
    Inkcite::Renderer::Style.new(nil, @view, { :left => '25%', :animation => 'video-frames 5s ease infinite' }).to_s.must_equal('-webkit-animation:video-frames 5s ease infinite;animation:video-frames 5s ease infinite;left:25%')
  end

  it 'can instantiate an animation keyframe' do
    Inkcite::Animation::Keyframe.new(5, @view, { :top => '-10px', :left => '22%' }).to_css('').must_equal('5% { left:22%;top:-10px }')
  end

  it 'can add style to an animation keyframe' do
    keyframe = Inkcite::Animation::Keyframe.new(25, @view)
    keyframe[:top] = '-15%'
    keyframe[:left] = '78px'
    keyframe.to_css('').must_equal('25% { left:78px;top:-15% }')
  end

  it 'can prefix a style on a keyframe' do
    keyframe = Inkcite::Animation::Keyframe.new(33, @view, { :transform => 'rotate(14deg)' })
    keyframe.to_css('').must_equal('33% { transform:rotate(14deg) }')
    keyframe.to_css('-webkit-').must_equal('33% { -webkit-transform:rotate(14deg) }')
  end

  it 'can instantiate an animation and add keyframes' do
    anim = Inkcite::Animation.new('snowflake7', @view)
    anim.add_keyframe 5, { :top => '-10px', :left => '22%', :transform => 'rotate(14deg)' }
    anim.add_keyframe 25, { :top => '100%', :left => '18%' }
    anim.to_keyframe_css.must_equal(%Q(@keyframes snowflake7 {\n5% { left:22%;top:-10px;transform:rotate(14deg) }\n25% { left:18%;top:100% }\n}\n@-webkit-keyframes snowflake7 {\n5% { -webkit-transform:rotate(14deg);left:22%;top:-10px }\n25% { left:18%;top:100% }\n}\n))
  end


end
