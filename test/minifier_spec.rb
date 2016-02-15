require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::View do

  before do
    @view = Inkcite::Email.new('test/project/').view(:production, :email)
    @view.is_enabled?(:minify).must_equal(true)
  end

  it "won't create compound words out of line breaks" do
    Inkcite::Minifier.html(%w(I am a multi-line string.), @view).must_equal('I am a multi-line string.')
  end

  it "removes trailing line-breaks" do
    Inkcite::Minifier.html(["This string has trailing line-breaks.\n\r\f"], @view).must_equal('This string has trailing line-breaks.')
  end

  it "removes HTML comments" do
    Inkcite::Minifier.remove_comments(%Q(I am <!-- This is an HTML comment -->not commented<!-- This is another comment --> out), @view).must_equal('I am not commented out')
  end

  it "removes multi-line HTML comments" do
    Inkcite::Minifier.remove_comments(%Q(I am not <!-- This is a\n\nmulti-line HTML\ncomment -->commented out), @view).must_equal('I am not commented out')
  end

  it "compresses CSS whitespace" do
    css = <<-EOF
          table {
            border-spacing: 0;
          }

          table, td {
            border-collapse: collapse;
          }

          a[href^=tel] {
            color: #336699;
            text-decoration: none;
          }

          div[style*="margin:16px 0"] {
            margin: 0 !important;
          }
    EOF

    Inkcite::Minifier.css(css, @view).must_equal(%Q(table{border-spacing:0}table, td{border-collapse:collapse}a[href^=tel]{color:#336699;text-decoration:none}div[style*="margin:16px 0"]{margin:0 !important}))
  end

  it "does not interfere with CSS3 animation keyframe at 0%" do
    css = <<-EOF
        @-webkit-keyframes s1a2 {
           0% {
             top: -3%;
             left: 68.75%
           }
           100% {
             top: 100%;
             left: 66%
           }
         }
    EOF
    Inkcite::Minifier.css(css, @view).must_equal('@-webkit-keyframes s1a2{0%{top:-3%;left:68.75%}100%{top:100%;left:66%}}')
  end

  it "does not interfere with CSS3 animation rotation in degrees" do
    css = <<-EOF
      @-webkit-keyframes snow1-anim8 {
        0%   { top: -3%; left: 57%; }
        100% { top: 100%; left: 60%; transform: rotate(-93deg); -webkit-transform: rotate(-93deg); }
      }
    EOF

    Inkcite::Minifier.css(css, @view).must_equal('@-webkit-keyframes snow1-anim8{0%{top:-3%;left:57%}100%{top:100%;left:60%;transform:rotate(-93deg);-webkit-transform:rotate(-93deg)}}')
  end

end
