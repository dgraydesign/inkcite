module Inkcite
  module Renderer
    class Sup < Base

      def render tag, opt, ctx

        html = ''

        if tag == '/sup'
          html << '</sup>'

        else

          sup = Element.new('sup', :style => { VERTICAL_ALIGN => :top })

          font_size = (opt[FONT_SIZE] || 10).to_i
          sup.style[FONT_SIZE] = px(font_size)

          line_height = (opt[LINE_HEIGHT] || 10).to_i
          sup.style[LINE_HEIGHT] = px(line_height)

          html << sup.to_s

        end

        html
      end

    end
  end
end

