module Inkcite
  module Renderer
    class Snow < SpecialEffect

      protected

      def config_all_children style, sfx

        style[:top] = "-#{px(sfx.max_size + 4)}"

      end

      def config_child n, child, style, animation, sfx

        speed = sfx.rand_speed

        size = sfx.rand_size
        style[:width] = px(size)
        style[:height] = px(size)
        style[BORDER_RADIUS] = px((size / 2.0).round) if sfx.src.blank?

        opacity = sfx.rand_opacity
        style[:opacity] = opacity if opacity < OPACITY_CEIL

        animation.duration = speed
        animation.delay = ((sfx.time / sfx.count) * n).round(1)
        animation.timing_function = Animation::LINEAR

        start_left = sfx.positions_x[n]

        # Determine the spread of the flakes - the bigger the spread, the larger
        # the variance between where the flake starts and where it ends.
        # Measured in %-width of the overall area.
        spread = sfx.opt[:spread].to_i
        half_spread = spread / 2.0
        spread_range = (-half_spread..half_spread)

        # Randomly choose where the snow will end its animation.  Prevent
        # it from going outside of the container.
        end_left = (start_left + rand(spread_range)).round
        if end_left < POSITION_FLOOR
          end_left = POSITION_FLOOR
        elsif end_left > POSITION_CEIL
          end_left = POSITION_CEIL
        end

        # Calculate the ending rotation for the flake, if rotation is enabled.
        end_rotation = sfx.rotation?? sfx.rand_rotation : 0

        # Start above the div area
        animation.add_keyframe(0, { :top => px(-size), :left => pct(start_left.round) })

        # End below the div area, applying rotation if necessary.
        keyframe = animation.add_keyframe(100, { :top => '100%', :left => pct(end_left) })
        keyframe[:transform] = "rotate(#{end_rotation}deg)" if end_rotation != 0

      end

      def config_effect_context sfx

        # Shuffle the x-positions so that the snowflakes fall across
        # the container's width in random order.
        sfx.positions_x.shuffle!

      end

      def defaults opt, ctx
        {
            :color => '#fff',
            :count => 3,
            SIZE_MIN => 6,
            SIZE_MAX => 18,
            SPEED_MIN => 3,
            SPEED_MAX => 8,
            :spread => 20,
            OPACITY_MIN => 0.5,
            OPACITY_MAX => 0.9,
            :time => 4
        }
      end

    end

  end
end
