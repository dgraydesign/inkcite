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

  it "wraps lines of CSS exceeding #{Inkcite::Minifier::MAXIMUM_LINE_LENGTH} characters" do
    css = <<-EOF
      .ExternalClass, .ReadMsgBody {
        width: 100%;
      }

      .ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {
        line-height: 100%;
      }

      #outlook a {
        padding: 0;
      }

      .yshortcuts, .yshortcuts a, .yshortcuts a:link, .yshortcuts a:visited, .yshortcuts a:hover, .yshortcuts a span {
        color: black;
        text-decoration: none !important;
        border-bottom: none !important;
        background: none !important;
      }

      XHTML-STRIPONREPLY {
        display: none;
      }

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

      div[style*="margin: 16px 0"] {
        margin: 0 !important;
      }

      td {
        font-family: sans-serif;
      }

      @media only screen and (max-width: 480px) {
        [class~="hide"] {
          display: none !important;
        }

        td[class~="drop"] {
          display: block;
          width: 100% !important;
          background-size: 100% auto !important;
          -moz-box-sizing: border-box;
          -webkit-box-sizing: border-box;
          box-sizing: border-box;
        }

        img[class~="fill"] {
          width: 100% !important;
          height: auto !important;
        }

        table[class~="fill"], td[class~="fill"] {
          width: 100% !important;
          background-size: 100% auto !important;
        }

        span[class~="img"] {
          display: block;
          background-position: center;
          background-size: cover;
        }

        a[class~="button"] {
          border: 2px solid #336699;
          border-radius: 5px;
          color: #336699 !important;
          display: block;
          font-weight: bold;
          margin-top: 5px;
          padding: 9px;
          text-align: center
        }

        img[class~="i01"] {
          content: url("images-optim/xxxxxx-xxxxxxxx.jpg?1457623072") !important;
        }

        td[class~="m1"] {
          font-size: 15px !important;
          line-height: 20px !important
        }

        td[class~="m2"] {
          text-align: center;
        }

        table[class~="m3"], td[class~="m3"] {
          padding: 15px !important;
        }

        img[class~="i02"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        td[class~="m4"] {
          height: 15px;
          display: block;
          width: 100%;
          margin-top: 12px;
          border-top: 1px dotted #cfcfcf;
        }

        img[class~="i03"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        img[class~="i04"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        table[class~="m5"] {
          background: #5EAE3F url(images-optim/xxx-xx-x.jpg?1457623072) bottom left / 100% auto no-repeat !important
        }

        img[class~="i05"] {
          content: url("images-optim/xxxxx.gif?1457623072") !important;
        }

        img[class~="i06"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        td[class~="m6"] {
          padding: 15px;
        }

        img[class~="i07"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        img[class~="i08"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        img[class~="i09"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        td[class~="m7"] {
          height: 15px;
        }

        img[class~="i10"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        img[class~="i11"] {
          content: url("images-optim/xxxxxx.jpg?1457623072") !important;
        }

        td[class~="m8"] {
          background: url(images-optim/xxxxx-xx.gif?1457623072) center no-repeat
        }

        img[class~="i12"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        img[class~="i13"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        img[class~="i14"] {
          content: url("images-optim/xxxxx.jpg?1457623072") !important;
        }

        span[class~="i15"] {
          background-image: url("images-optim/xxx.gif?1457623072");
          float: right;
          height: 101px;
          width: 139px
        }
      }
    EOF

    minified_css = Inkcite::Minifier.css(css, @view)
    minified_css.split("\n").all? { |l| l.length <= Inkcite::Minifier::MAXIMUM_LINE_LENGTH }.must_equal(true)
  end

end
