module Inkcite
  module Renderer

    # Animated CSS fireworks special effect based on the technique
    # by Eddie Lin https://codepen.io/yshlin/pen/ylDEk
    class Fireworks < SpecialEffect

      private

      # Each firework will move this many positions during the
      # entire animation.
      TOTAL_POSITIONS = 5

      # The number of hue degrees to randomly alter the hue of each spark
      HUE_RANGE = 45
      HUE_RANGE_2X = HUE_RANGE * 2

      # Names of the attributes controlling min and max explosion size.
      RADIUS_MIN = :'min-radius'
      RADIUS_MAX = :'max-radius'

      # Attributes used for color generation
      SATURATION = 100
      LUMINANCE = 50

      def create_explosion_animation n, hue, duration, delay, sfx

        # Calculate the radius size for this explosion
        min_radius = sfx[RADIUS_MIN].to_i
        max_radius = sfx[RADIUS_MAX].to_i
        radius_range = (min_radius..max_radius)
        radius = rand(radius_range).round(0)
        half_radius = radius / 2.0

        sparks = sfx[:sparks].to_i

        box_shadow = sparks.times.collect do |n|

          # Pick a random position for this spark to move to
          x = (rand(radius) - half_radius).round(0)
          y = (rand(radius) - half_radius).round(0)

          # Randomly pick a slightly different hue for this spark
          _hue = hue + HUE_RANGE - rand(HUE_RANGE_2X)
          color = Inkcite::Util::hsl_to_color(_hue, SATURATION, LUMINANCE)

          "#{px(x)} #{px(y)} #{color}"
        end

        anim = Inkcite::Animation.new(sfx.animation_class_name(n, 'bang'), sfx.ctx)
        anim.duration = duration
        anim.delay = delay if delay > 0
        anim.timing_function = Inkcite::Animation::EASE_OUT
        anim.add_keyframe 100, { BOX_SHADOW => box_shadow.join(', ') }

        sfx.animations << anim

        anim
      end

      def create_gravity_animation sfx

        anim = Animation.new('gravity', sfx.ctx)

        # All fireworks fade to zero opacity and size by the end of the gravity cycle.
        keyframe = anim.add_keyframe 100, { :opacity => 0, :width => 0, :height => 0 }

        # Check to see if gravity has been specified for the fireworks.  If so
        # apply it as a vertical translation (positive equals downward)
        gravity = sfx[:gravity].to_i
        keyframe[:transform] = "translateY(#{px(gravity)})" if gravity != 0

        sfx.animations << anim

      end

      def create_position_animation n, duration, delay, sfx

        # This is the percentage amount of the total animation that will
        # be spent in each position.
        keyframe_duration = (100 / TOTAL_POSITIONS.to_f)

        # This is the total number of random spots in the container that
        # could have a firework.
        position_count = TOTAL_POSITIONS * sfx.count
        positions = sfx.equal_distribution(position_count).shuffle

        anim = Inkcite::Animation.new(sfx.animation_class_name(n, 'position'), sfx.ctx)
        anim.duration = duration
        anim.delay = delay if delay > 0
        anim.timing_function = Inkcite::Animation::LINEAR

        percent = 0
        TOTAL_POSITIONS.times do |n|

          top = positions[rand(position_count)]
          left = positions[rand(position_count)]

          keyframe = anim.add_keyframe(percent, { :top => pct(top), :left => pct(left) })
          keyframe.duration = keyframe_duration - 0.1

          percent += keyframe_duration
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

        # Create the global gravity animation that is consistent for all fireworks.
        # There is no variance in this animation so it is created and added to the
        # context only once.
        create_gravity_animation(sfx)

      end

      def config_child n, child, style, animation, sfx

        # If all of the fireworks are different possible sizes
        # then pick a random size for this child.
        unless sfx.same_size?
          size = sfx.rand_size
          style[:width] = px(size)
          style[:height] = px(size)
        end

        # Randomly pick a color for this explosion by choosing a
        # random hue and then converting it to a hex color
        hue = (sfx[:hue] || rand(360)).to_i
        color = Inkcite::Util::hsl_to_color(hue, 100, 50)
        style[BACKGROUND_COLOR] = color

        # After the first child, each firework should have a random
        # delay before its animation starts - giving the different
        # fireworks a staggered launch.
        delay = n > 0 ? 0.25 + rand(sfx.count).round(2) : 0

        # This is the total amount of time it will take the firework to
        # move through each of its positions.
        position_speed = sfx.rand_speed

        # This is the speed the firework animates it's explosion and gravity
        # components - which need to repeat n-number of times based on the
        # total number of positions.
        explosion_speed = (position_speed / TOTAL_POSITIONS.to_f).round(2)

        gravity_animation = Inkcite::Animation.new('gravity', sfx.ctx)
        gravity_animation.duration = explosion_speed
        gravity_animation.delay = delay if n > 0
        gravity_animation.timing_function = Inkcite::Animation::EASE_IN

        composite_animation = Inkcite::Animation::Composite.new
        composite_animation << create_explosion_animation(n, hue, explosion_speed, delay, sfx)
        composite_animation << gravity_animation
        composite_animation << create_position_animation(n, position_speed, delay, sfx)

        style[:animation] = composite_animation

        # # Each firework consists of three separate animations - one to animate
        # # the explosion, one to fade out/apply gravity and one to move the
        # # firework through it's fixed positions.
        # style[:animation] = "1s bang ease-out infinite, 1s gravity ease-in infinite, #{TOTAL_POSITIONS}s position linear infinite"

        # style[ANIMATION_DURATION] = "#{explosion_speed}s, #{explosion_speed}s, #{position_speed}s"

      end

      def defaults opt, ctx
        {
            :bgcolor => '#000000',
            :sparks => 50,
            :count => 2,
            :gravity => 200,
            RADIUS_MIN => 150,
            RADIUS_MAX => 400,
            SIZE_MIN => 10,
            SIZE_MAX => 10,
            SPEED_MIN => 5,
            SPEED_MAX => 10,
        }
      end

    end
  end
end
