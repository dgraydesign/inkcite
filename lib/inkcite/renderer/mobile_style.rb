module Inkcite
  module Renderer

    class MobileStyle < Responsive

      def render tag, opt, ctx

        klass = detect(opt[:name], opt[:id])
        if klass.blank?
          ctx.error('Declaring a mobile style requires a name attribute')

        else

          mq = ctx.media_query

          declarations = opt[:style]
          if declarations.blank?
            ctx.error('Declaring a mobile style requires a style attribute', { :name => klass })

          elsif !mq.find_by_klass(klass).nil?
            ctx.error('A mobile style was already defined with that class name', { :name => klass, :style => declarations })

          else

            # Create a new rule with the specified klass and declarations but mark
            # it inactive.  Like other rule presets, it will be activated on first use.
            mq << Rule.new(UNIVERSAL, klass, declarations, false)

          end

        end

        nil
      end

    end

  end
end

