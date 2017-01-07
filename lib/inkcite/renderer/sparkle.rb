module Inkcite
  module Renderer
    class Sparkle < SpecialEffect

      protected

      def config_child n, child, style, animation, sfx

        # Random size
        size = sfx.rand_size
        style[:height] = px(size)
        style[:width] = px(size)
        style[BORDER_RADIUS] = px((size / 2).round) unless sfx.src

        # Random opacity
        opacity = sfx.rand_opacity
        style[:opacity] = opacity if opacity < OPACITY_CEIL

        # Random position
        style[:top] = pct(sfx.positions_y[n].round(0))
        style[:left] = pct(sfx.positions_x[n].round(0))

        # Calculate the ending rotation for the flake, if rotation is enabled.
        end_rotation = sfx.rotation? ? sfx.rand_rotation : 0
        half_rotation = (end_rotation / 2.0).round(1)

        #animation.timing_function = Animation::EASE

        speed = sfx.rand_speed

        max_delay = speed * 0.1
        delay = rand(max_delay).round(1)
        animation.duration = (speed + delay).round(1)

        delay_percent = 100 - ((delay / animation.duration) * 100).round(0)
        midpoint_percent = (delay_percent / 2.0).round(0)

        # Start above the div area
        keyframe = animation.add_keyframe(0, { :transform => 'scale(0.0)' })
        keyframe.append(:transform, "rotate(0deg)") if half_rotation != 0

        keyframe = animation.add_keyframe(midpoint_percent, { :transform => 'scale(1.0)' })
        keyframe.append(:transform, "rotate(#{half_rotation}deg)") if half_rotation != 0

        keyframe = animation.add_keyframe(delay_percent, { :transform => 'scale(0.0)' })
        keyframe.append(:transform, "rotate(#{end_rotation}deg)") if end_rotation != 0

        keyframe = animation.add_keyframe(100, { :transform => 'scale(0.0)' })
        keyframe.append(:transform, "rotate(#{end_rotation}deg)") if end_rotation != 0

      end

      def config_effect_context sfx

        # Randomly shuffle the x- and y-positions for the sparkles.
        sfx.positions_x.shuffle!
        sfx.positions_y.shuffle!

      end

      def defaults opt, ctx
        {
            :count => 6,
            :color => '#fff',
            OPACITY_MIN => 0.33,
            OPACITY_MAX => 1.0,
            SIZE_MIN => 6,
            SIZE_MAX => 24,
            SPEED_MIN => 0.5,
            SPEED_MAX => 2.0,
            :time => 4
        }
      end

    end
  end
end
