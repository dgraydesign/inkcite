module Inkcite
  module Renderer

    # Animated CSS fireworks special effect based on the technique
    # by Eddie Lin https://codepen.io/yshlin/pen/ylDEk
    class Fireworks < SpecialEffect

      private

      # The number of hue degrees to randomly alter the hue of each spark
      HUE_RANGE = :'hue-range'

      # Names of the attributes controlling min and max explosion size.
      DIAMETER_MIN = :'min-diameter'
      DIAMETER_MAX = :'max-diameter'

      # Attributes used for color generation
      SATURATION = 100
      LUMINANCE = 50

      def config_effect_context sfx

        count = sfx.count

        # Make sure the total number of stops (formerly TOTAL_POSITIONS)
        # is specified as an integer.
        sfx[:stops] = sfx[:stops].to_i

        # Total number of firework instances multiplied by the number
        # of positions each firework will cycle through.
        position_count = sfx[:stops] * count
        positions = sfx.equal_distribution(sfx.position_range, position_count)

        sfx[:x_positions] = positions
        sfx[:y_positions] = positions.dup

        # Equal distribution of hues based on the number of fireworks
        # if the rainbow option is selected
        sfx[:hues] = sfx.equal_distribution(0..360, count)

      end

      def create_explosion_animation n, hue, duration, delay, sfx

        # Calculate the radius size for this explosion
        min_diameter = sfx[DIAMETER_MIN].to_i
        max_diameter = sfx[DIAMETER_MAX].to_i
        diameter_range = (min_diameter..max_diameter)

        hue_range = (sfx[HUE_RANGE] || 40).to_i
        hue_range_2x = hue_range * 2

        sparks = sfx[:sparks].to_i

        angle = 0
        angle_step = 360 / sparks.to_f

        box_shadow = sparks.times.collect do |n|

          # Pick a random angle.
          angle_radians = angle * PI_OVER_180
          angle += angle_step

          # Pick a random radius
          radius = rand(diameter_range) / 2.0

          # Pick a random position for this spark to move to
          x = (radius * Math::cos(angle_radians)).round(0)
          y = (radius * Math::sin(angle_radians)).round(0)

          # Randomly pick a slightly different hue for this spark
          _hue = hue + hue_range - rand(hue_range_2x)
          color = Inkcite::Util::hsl_to_color(_hue, SATURATION, LUMINANCE)

          "#{px(x)} #{px(y)} #{color}"
        end

        anim = Inkcite::Animation.new(sfx.animation_class_name(n, 'bang'), sfx.ctx)
        anim.duration = duration
        anim.delay = delay if delay > 0
        anim.timing_function = Inkcite::Animation::EASE_OUT_QUART
        anim.add_keyframe 100, { BOX_SHADOW => box_shadow.join(', ') }

        sfx.animations << anim

        anim
      end

      def create_decay_animation sfx

        anim = Animation.new(DECAY_ANIMATION_NAME, sfx.ctx)

        # All fireworks fade to zero opacity and size by the end of the decay cycle.
        keyframe = anim.add_keyframe 100, { :opacity => 0, :width => 0, :height => 0 }

        # Check to see if gravity has been specified for the fireworks.  If so
        # apply it as a vertical translation (positive equals downward)
        gravity = sfx[:gravity].to_i
        keyframe[:transform] = "translateY(#{px(gravity)})" if gravity != 0

        sfx.animations << anim

      end

      def create_position_animation n, duration, delay, sfx

        stops = sfx[:stops]

        anim = Inkcite::Animation.new(sfx.animation_class_name(n, 'position'), sfx.ctx)
        anim.duration = duration
        anim.delay = delay if delay > 0
        anim.timing_function = Inkcite::Animation::LINEAR

        x_positions = sfx[:x_positions]
        y_positions = sfx[:y_positions]

        # This is the percentage amount of the total animation that will
        # be spent in each position.
        keyframe_duration = 100.0 / stops.to_f

        percent = 0
        stops.times do |n|

          # Pick a random position for this firework
          top = y_positions.delete_at(rand(y_positions.length))
          left = x_positions.delete_at(rand(x_positions.length))

          # Calculate when the next keyframe will trigger.
          next_keyframe = percent + keyframe_duration

          # Calculate when this frame should end
          end_percent = n < stops - 1 ? (next_keyframe - 0.1).round(1) : 100

          keyframe = anim.add_keyframe(percent.round(1), { :top => pct(top), :left => pct(left) })
          keyframe.end_percent = end_percent

          percent = next_keyframe
        end

        sfx.animations << anim

        anim
      end

      protected

      def config_all_children style, sfx

        # If all of the sparks in the firework have the same size
        # (e.g. min-size equals max-size) then save some CSS space
        # by defining it once for all children.
        if sfx.same_size?
          style[:width] = px(sfx.min_size)
          style[:height] = px(sfx.min_size)
        end

        # Make sure all explosions start off-screen.
        style[:top] = "-#{px(sfx.max_size)}"

        style[BORDER_RADIUS] = '50%'

        sparks = sfx[:sparks].to_i

        # All sparks start with a box shadow at their exact center,
        # all in white.
        box_shadow = sparks.times.collect { |n| '0 0 #fff' }
        style[BOX_SHADOW] = box_shadow.join(', ')

        # Create the global decay animation that is consistent for all fireworks.
        # There is no variance in this animation so it is created and added to the
        # context only once.
        create_decay_animation(sfx)

      end

      def config_child n, child, style, animation, sfx

        # If all of the fireworks are different possible sizes
        # then pick a random size for this child.
        unless sfx.same_size?
          size = sfx.rand_size
          style[:width] = px(size)
          style[:height] = px(size)
        end

        # If rainbow is specified, choose the next color in the array - otherwise
        # choose a random hue unless a specific one has been specified.
        hue = sfx[:rainbow] ? sfx[:hues][n] : (sfx[:hue] || rand(360)).to_i

        # Randomly pick a color for this explosion by choosing a
        # random hue and then converting it to a hex color
        color = Inkcite::Util::hsl_to_color(hue, 100, 50)
        style[BACKGROUND_COLOR] = color

        # After the first child, each firework should have a random
        # delay before its animation starts - giving the different
        # fireworks a staggered launch.
        delay = n > 0 ? 0.25 + rand(sfx.count).round(2) : 0

        # This is the total amount of time it will take the firework to
        # move through each of its positions.
        position_speed = sfx.rand_speed

        # This is the speed the firework animates it's explosion and decay
        # components - which need to repeat n-number of times based on the
        # total number of positions.
        explosion_speed = (position_speed / sfx[:stops].to_f).round(2)

        gravity_animation = Inkcite::Animation.new(DECAY_ANIMATION_NAME, sfx.ctx)
        gravity_animation.duration = explosion_speed
        gravity_animation.delay = delay if n > 0
        gravity_animation.timing_function = Inkcite::Animation::EASE_IN_CUBIC

        composite_animation = Inkcite::Animation::Composite.new
        composite_animation << create_explosion_animation(n, hue, explosion_speed, delay, sfx)
        composite_animation << gravity_animation
        composite_animation << create_position_animation(n, position_speed, delay, sfx)

        style[:animation] = composite_animation

      end

      def defaults opt, ctx
        {
            :bgcolor => '#000000',
            :sparks => 50,
            :count => 2,
            :gravity => 200,
            DIAMETER_MIN => 25,
            DIAMETER_MAX => 200,
            SIZE_MIN => 10,
            SIZE_MAX => 10,
            SPEED_MIN => 5,
            SPEED_MAX => 10,
            :stops => 5,
        }
      end

      private

      DECAY_ANIMATION_NAME = 'decay'

    end
  end
end
