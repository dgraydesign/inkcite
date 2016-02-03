module Inkcite
  module Renderer
    class Snow < ContainerBase

      # Ambient snow special effect renderer courtesy of
      # http://freshinbox.com/blog/ambient-animations-in-email-snow-and-stars/
      def render tag, opt, ctx

        return '</div>' if tag == '/snow'

        # Get a unique ID for this wrap element.
        uid = ctx.unique_id(:snow)

        # Total number of flakes to animate
        flakes = (opt[:flakes] || 3).to_i

        # This is the general class applied to all snow elements within this
        # wrapping container.
        all_flakes_class = ctx.development? ? "snow#{uid}-flakes" : "s#{uid}fs"
        flake_prefix = ctx.development? ? "snow#{uid}-flake" : "s#{uid}f"
        anim_prefix = ctx.development? ? "snow#{uid}-anim" : "s#{uid}a"

        # Grab the min and max sizes for the flakes or inherit default values.
        flake_min_size = (opt[FLAKE_SIZE_MIN] || 6).to_i
        flake_max_size = (opt[FLAKE_SIZE_MAX] || 18).to_i

        # Grab the min and max speeds for the flakes, the smaller the value the
        # faster the flake moves.
        flake_min_speed = (opt[FLAKE_SPEED_MIN] || 3).to_f
        flake_max_speed = (opt[FLAKE_SPEED_MAX] || 8).to_f

        # Determine the spread of the flakes - the bigger the spread, the larger
        # the variance between where the flake starts and where it ends.
        # Measured in %-width of the overall area.
        spread = (opt[:spread] || 20).to_i
        half_spread = spread / 2.0

        # Determine the opacity variance.
        flake_min_opacity = (opt[FLAKE_OPACITY_MIN] || 0.5).to_f
        flake_max_opacity = (opt[FLAKE_OPACITY_MAX] || 0.9).to_f

        # Overall time for the initial distribution of flakes.
        end_time = (opt[:time] || 4).to_f

        # Setup some ranges for easier random numbering.
        size_range = (flake_min_size..flake_max_size)
        speed_range = (flake_min_speed..flake_max_speed)
        spread_range = (-half_spread..half_spread)
        opacity_range = (flake_min_opacity..flake_max_opacity)

        # Snowflake color.
        color = hex(opt[:color] || '#fff')

        # Initialize the wrap that will hold each of the snowflakes and the
        # content within that will have it's
        div_wrap = Element.new('div')

        # Resolve the wrapping class name - readable name in development,
        # space-saving name in all other environments.
        wrap_class = ctx.development? ? "snow#{uid}-wrap" : "s#{uid}w"
        div_wrap[:class] = wrap_class

        # Background color gets applied directly to the div so it renders
        # consistently in all clients - even those that don't support the
        # snow effect.
        mix_background div_wrap, opt, ctx

        # Kick things off by rendering the wrapping div.
        html = div_wrap.to_s

        # Get the number of flakes that should be included.  Create a child div for
        # each flake that can be sized, animated uniquely.
        flakes.times do |flake|
          html << %Q(<div class="#{all_flakes_class} #{flake_prefix}#{flake + 1}"></div>)
        end

        # Check to see if there is a height required for the wrap element - otherwise
        # the wrap will simply enlarge to hold all of the contents within.
        wrap_height = opt[:height].to_i

        # Will hold all of the styles as they're assembled.
        style = []

        # Hide the snow effect from any non-webkit email clients.
        style << '@media screen and (-webkit-min-device-pixel-ratio: 0) {'

        # Snow wrapping element in-which the snow flakes will be animated.
        style << "  .#{wrap_class} {"
        style << '    position: relative;'
        style << '    overflow: hidden;'
        style << '    width: 100%;'
        style << "    height: #{px(wrap_height)};" if wrap_height > 0
        style << '  }'

        # Common attributes for all snowflakes.
        style << "  .#{all_flakes_class} {"
        style << '    position: absolute;'
        style << "    top: -#{flake_max_size + 4}px;"
        style << "    background-color: #{color};"
        style << '  }'

        # Space the snowflakes generally equally across the width of the
        # container div.  Random distribution sometimes ends up with
        # snowflakes clumped at one edge or the other.
        flake_spacing = 100 / flakes.to_f

        # Now build up a pool of equally-spaced starting positions.
        # TODO: This is probably a perfect spot to use inject()
        start_left = flake_spacing / 2.0
        start_positions = [ start_left ]
        (flakes - 1).times { |f| start_positions << start_left += flake_spacing }

        # Randomize the starting positions - otherwise they draw right-to-left
        # as starting positions are popped from the pool.
        start_positions.shuffle!

        # Snowflakes will be dispersed equally across the total time
        # of the animation making for a smoother, more balanced show.
        start_interval = end_time / flakes.to_f
        start_time = 0

        # Now add individual class definitions for each flake with unique size,
        # speed and starting position.  Also add the animation trigger that loops
        # infinitely, starts at a random time and uses a random speed to completion.
        flakes.times do |flake|

          speed = rand(speed_range).round(1)
          size = rand(size_range)

          opacity = rand(opacity_range).round(1)
          if opacity < OPACITY_FLOOR
            opacity = OPACITY_FLOOR
          elsif opacity > OPACITY_CEIL
            opacity = OPACITY_CEIL
          end

          style << "  .#{flake_prefix}#{flake + 1} {"
          style << "    height: #{px(size)};"
          style << "    width: #{px(size)};"
          style << "    border-radius: #{px((size / 2.0).round)};"
          style << "    opacity: #{opacity};" if opacity < OPACITY_CEIL
          style << "    -webkit-animation: #{anim_prefix}#{flake + 1} #{speed}s linear #{start_time.round(1)}s infinite;"
          style << '  }'

          start_time += start_interval
        end

        # Declare each of the flake animations.
        flakes.times do |flake|

          start_left = start_positions.pop

          # Randomly choose where the snow will end its animation.  Prevent
          # it from going outside of the container.
          end_left = (start_left + rand(spread_range)).round
          if end_left < POSITION_FLOOR
            end_left = POSITION_FLOOR
          elsif end_left > POSITION_CEIL
            end_left = POSITION_CEIL
          end

          style << "  @-webkit-keyframes #{anim_prefix}#{flake + 1} {"
          style << "    0%   { top: -3%; left: #{start_left}%; }"
          style << "    100% { top: 100%; left: #{end_left}%; }"
          style << '  }'

        end

        style << '}'

        ctx.styles << style.join("\n")

        html

      end

      private

      # Size constraints on the flakes.
      FLAKE_SIZE_MIN = :'min-size'
      FLAKE_SIZE_MAX = :'max-size'

      # Speed constraints on the flakes.
      FLAKE_SPEED_MIN = :'min-speed'
      FLAKE_SPEED_MAX = :'max-speed'

      # Opacity constraints.
      FLAKE_OPACITY_MIN = :'min-opacity'
      FLAKE_OPACITY_MAX = :'max-opacity'
      OPACITY_FLOOR = 0.2
      OPACITY_CEIL = 1.0

      # Position min and max preventing snow flakes
      # from leaving the bounds of the container.
      POSITION_FLOOR = 0
      POSITION_CEIL = 100

    end

  end
end
