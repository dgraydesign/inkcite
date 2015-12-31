module Inkcite
  module Renderer
    class Span < ContainerBase

      def render tag, opt, ctx
        if tag == '/span'
          '</span>'
        else
          mix_all Element.new('span'), opt, ctx
        end
      end

    end
  end
end

