module Inkcite
  module Renderer
    class SpecialEffect < ContainerBase

      # A convenience class for accessing the attributes that are
      # common to special effects like snow and sparkle.
      class EffectContext

        attr_reader :uuid, :animations

        # Expose the opt and ctx attributes
        attr_reader :opt, :ctx

        # Allow sfx to be treated equivalent to the options map it wraps.
        # This makes it easy for the consumer to set custom state into
        # the context (during config_effect_context) and then use those
        # values during the rendering methods.
        delegate :[], :[]=, :to => :opt

        def initialize tag, opt, ctx, defaults={}

          @tag = tag

          # Merge the provided opts over the defaults to ensure the values
          # provided by the developer take precedence.
          @opt = defaults.merge(opt)
          @ctx = ctx

          # Request a unique ID for this special effect which will be used
          # to uniquely identify the classes and animations associated with
          # this special effect.
          @uuid = ctx.unique_id(:sfx)

          # Will hold all of the Animations while the children are
          # assembled and then added to the styles array at the end
          # so that all keyframes are together in the source.
          @animations = []

        end

        def all_children_class_name
          obfuscate_class_names? ? "sfx#{@uuid}c" : "#{@tag}#{@uuid}-children"
        end

        def animation_class_name child_index, suffix=nil

          base = obfuscate_class_names? ? "#{@tag}#{@uuid}-anim#{child_index + 1}" : "sfx#{@uuid}a#{child_index + 1}"
          unless suffix.blank?
            base << '-'
            base << (obfuscate_class_names? ? suffix[0] : suffix)
          end

          base
        end

        def child_class_name child_index
          obfuscate_class_names? ? "sfx#{@uuid}c#{child_index + 1}" : "#{@tag}#{@uuid}-child#{child_index + 1}"
        end

        def color
          Renderer.hex(@opt[:color])
        end

        # Returns the number of children in the special effects - e.g. the number
        # of snowflakes or sparkles in the animation.  :flakes and :sparks are
        # technically deprecated.
        def count
          @opt[:count].to_i
        end

        def equal_distribution range, qty

          # Space the children generally equally across the width of the
          # container div.  Random distribution sometimes ends up with
          # children clumped at one edge or the other.
          spacing = (range.last - range.first) / qty.to_f

          # Now build up a pool of equally-spaced starting positions.
          # TODO: This is probably a perfect spot to use inject()
          start_left = range.first + (spacing / 2.0)

          # This array will hold all of the positions
          positions = [start_left]

          # Now, for the remaining positions needed, adjust by the
          # spacing and push onto the list.
          (qty - 1).times { |f| positions << start_left += spacing }

          positions.collect { |p| p.round(0) }
        end

        def height
          @opt[:height].to_i
        end

        def insets
          @opt[:insets].to_i
        end

        def max_opacity
          @opt[OPACITY_MAX].to_f
        end

        def max_size
          @opt[SIZE_MAX].to_i
        end

        def min_opacity
          @opt[OPACITY_MIN].to_f
        end

        def max_speed
          @opt[SPEED_MAX].to_f
        end

        def min_size
          @opt[SIZE_MIN].to_i
        end

        def min_speed
          @opt[SPEED_MIN].to_f
        end

        def obfuscate_class_names?
          @ctx.production?
        end

        def opacity_range
          (min_opacity..max_opacity)
        end

        def rand_opacity
          rand(opacity_range).round(1)
        end

        def rand_rotation
          rand(rotation_range).round(1)
        end

        def rand_size
          rand(size_range).round(0)
        end

        def rand_speed
          rand(speed_range).round(1)
        end

        def rotation?
          @opt[:rotate] || @opt[:rotation]
        end

        def rotation_range
          (-270..270)
        end

        def same_size?
          min_size == max_size
        end

        def size_range
          (min_size..max_size)
        end

        def speed_range
          (min_speed..max_speed)
        end

        def src
          return @src if defined?(@src)

          # Check to see if a source image has been specified for the snowflakes.
          @src = @opt[:src]

          # Release the image name if one has been provided but doesn't exist in
          # the project - this will cause the special effect to default to the
          # non-image default behavior.
          @src = nil if @src && !@ctx.assert_image_exists(@src)

          @src
        end

        def position_range
          min = POSITION_FLOOR + insets
          max = POSITION_CEIL - insets
          (min..max)
        end

        # Creates a permanent list of positions (as percentages of the wrap container's
        # total width) which can be used for starting or ending position to equally
        # space animated elements.
        def positions_x
          @positions_x ||= equal_distribution(position_range, count)
        end

        # Creates a permanent list of positions (as percentages of the wrap container's
        # total height) which can be used for starting or ending position to equally
        # space animated elements.
        def positions_y
          @positions_y ||= equal_distribution(position_range, count)
        end

        def start_time child_index
          ((time / count) * child_index).round(1)
        end

        def time
          @opt[:time].to_f
        end

        # Amount of time between each child starting its animation to create a
        # even but varied distribution.
        def time_interval
          time / count.to_f
        end

        # Returns true if CSS animations should be limited to webkit-
        # powered email clients.
        def webkit_only?
          !(@ctx.development? || @ctx.browser?)
        end

        def wrap_class_name
          obfuscate_class_names? ? "sfx#{@uuid}w" : "#{@tag}#{@uuid}-wrap"
        end

      end

      public

      def render tag, opt, ctx

        # If the closing tag was received (e.g. /snow) then close the wrapper
        # div that was rendered by the opening tag.
        return '</div>' if tag.start_with?('/')

        # Retrieve the special effects default values (times, number of units, etc.)
        _defaults = defaults(opt, ctx)

        # Create a special effects context that simplifies working with the
        # opts, defaults and manages the styles/classes necessary to animate
        # the special effect.
        sfx = EffectContext.new(tag, opt, ctx, _defaults)

        # Provide the extending class with an opportunity to configure the
        # effect context prior to any rendering.
        config_effect_context sfx

        html = []
        styles = []

        # If this is the first special effect to be included in the email
        # we need to disable the CSS animation from Gmail - which only
        # accepts part of its <styles> leading to unexpected whitespace.
        # By putting this invalid CSS into the <style> block, Gmail's
        # very strict parser will exclude the entire block, preventing
        # the animation from running.
        # https://emails.hteumeuleu.com/troubleshooting-gmails-responsive-design-support-ad124178bf81#.8jh1vn9mw
        if ctx.email? && sfx.uuid == 1
          styles << Inkcite::Renderer::Style.new(".gmail-fix", sfx.ctx, { FONT_SIZE => '3*px' })
        end

        # Create the <div> that wraps the entire animation.
        create_wrap_element html, sfx

        # Create the Style that defines the look of the wrapping container
        create_wrap_style styles, sfx

        # Create the Style that is applied to all children in the animation.
        create_all_children_style styles, sfx

        # Now create each of the child elements (e.g. the snowflakes) that
        # will be animated in this effect.  Each child is created and animated
        # at the same time.
        create_child_elements html, styles, sfx

        # Append all of the Keyframes to the end of the styles, now that
        # the individual children are configured.
        sfx.animations.each { |a| styles << a.to_keyframe_css }

        # Push the completed list of styles into the context's stack.
        ctx.styles << styles.join("\n")

        html.join("\n")

      end

      protected

      # Position min and max preventing animated elements
      # from leaving the bounds of the container.
      POSITION_FLOOR = 0
      POSITION_CEIL = 100

      # Size constraints on the animated children.
      SIZE_MIN = :'min-size'
      SIZE_MAX = :'max-size'

      # Speed constraints on the children.
      SPEED_MIN = :'min-speed'
      SPEED_MAX = :'max-speed'

      # Opacity constraints on the children
      OPACITY_MIN = :'min-opacity'
      OPACITY_MAX = :'max-opacity'
      OPACITY_CEIL = 1.0

      # Static constants for animation-specific CSS
      ANIMATION_DELAY = :'animation-delay'
      ANIMATION_DURATION = :'animation-duration'

      # The extending class can override this method to perform any
      # additional configuration on the style that affects all
      # children in the animation.
      def config_all_children style, sfx
        # This space left intentionally blank
      end

      # The extending class must implement this method to customize
      # and animate each child.
      def config_child n, child, style, animation, sfx
        raise 'Classes extending SpecialEffect must implement defaults(child, style, animation, keyframes, sfx)'
      end

      # The extending class can implement this method to customize
      # the EffectContext prior to any HTML or CSS generation.
      def config_effect_context sfx
        # This space left intentionally blank
      end

      # The extending class can override this method to perform any
      # additional configuration on the <div> that wraps the entire
      # animation.
      def config_wrap_element div, sfx
        # This space left intentionally blank
      end

      # The extending class can override this method to customize
      # the wrap <div>'s style.
      def config_wrap_style style, sfx
        # This space left intentionally blank
      end

      # The extending class must override this method and return the defaults
      # for the special effect as a map.
      def defaults opt, ctx
        raise 'Classes extending SpecialEffect must implement defaults(opt, ctx)'
      end

      private

      # Creates the Style that applies to /all/ children.
      def create_all_children_style styles, sfx

        style = Inkcite::Renderer::Style.new(".#{sfx.all_children_class_name}", sfx.ctx, { :position => :absolute })

        # If no image has been provided, make the background a solid color
        # otherwise set the background to the image source and fill the
        # available space.
        src = sfx.src
        if src.blank?
          color = sfx.color
          style[BACKGROUND_COLOR] = color unless none?(color)
        else
          style[BACKGROUND_IMAGE] = "url(#{sfx.ctx.image_url(src)})"
          style[BACKGROUND_SIZE] = '100%'
        end

        # Provide the extending class with a chance to apply additional
        # styles to all children.
        config_all_children style, sfx

        styles << style

      end

      # Creates n-number of child <div> objects and assigns the all-child and each-child
      # CSS classes to them allowing each to be sized, animated uniquely.
      def create_child_elements html, styles, sfx

        sfx.count.times do |n|

          child_class_name = sfx.child_class_name(n)

          # This is the child HTML element
          child = Inkcite::Renderer::Element.new('div', { :class => quote("#{sfx.all_children_class_name} #{child_class_name}") })

          # This is the custom style to be applied to the child.
          style = Inkcite::Renderer::Style.new(".#{child_class_name}", sfx.ctx)

          # This is the animation declaration (timing, duration, etc.) for this child.
          animation = Inkcite::Animation.new(sfx.animation_class_name(n), sfx.ctx)

          # Provide the extending class with a chance to configure the child
          # and its style.
          config_child n, child, style, animation, sfx

          # Add the child's HTML element into the email.
          html << child.to_s + '</div>'

          # If the extending class actually defined an animation for this child
          # then assign it and add it to the list of animations to be appended
          # after the styles are injected.
          unless animation.blank?

            sfx.animations << animation

            # If the extending class didn't assign the animation already, then
            # assign it to the child's style - this adds itself with the appropriate
            # browser prefixes.
            style[:animation] = animation if style[:animation].blank?

          end

          # Append the child's custom style, unless blank (meaning the extending
          # class did not customize the child's styles directly).
          styles << style unless style.blank?

        end

      end

      # Creates the <div> that wraps the entire animation.  The children of this container
      # will be animated based on the parameters of the effect.
      def create_wrap_element html, sfx

        # Initialize the wrap that will hold each of the children and wraps the content
        # over which the special effect will animate.
        div = Inkcite::Renderer::Element.new('div', { :class => quote(sfx.wrap_class_name) })

        # Background color gets applied directly to the div so it renders consistently
        # in all clients - even those that don't support special effects.
        mix_background div, sfx.opt, sfx.ctx

        # Text alignment within the wrapper
        mix_text_align div, sfx.opt, sfx.ctx

        # Provide the extending class with a chance to make additional
        # configuration changes to the wrap element.
        config_wrap_element div, sfx

        html << div.to_s

      end

      def create_wrap_style styles, sfx

        # Initialize the class declaration that will be applied to the
        # wrapping container.
        style = Inkcite::Renderer::Style.new(".#{sfx.wrap_class_name}", sfx.ctx, { :position => :relative, :overflow => :hidden, :width => '100%' })

        # If a specific height has been specified for the wrap class, add
        # it to the style.
        height = sfx.height
        style[:height] = px(height) if height > 0

        # Provide the extending class with a chance to do any additional
        # customization to this style.
        config_wrap_style style, sfx

        styles << style

      end

    end
  end
end
