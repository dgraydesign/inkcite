module Inkcite
  module Renderer

    # Better video preview courtesy of @stigm
    # https://medium.com/cm-engineering/better-video-previews-for-email-12432ce71846#.2o9qgc7hd
    class VideoPreview < ImageBase

      def render tag, opt, ctx

        # Get a unique ID for this video which will make its CSS classes
        # distinct from other videos in the email.
        uid = ctx.unique_id(:video)

        # Links need an ID
        id = opt[:id] || "video-preview#{uid}"

        # Grab the URL for the video - this is passed on to the {a} Helper and
        # the user will be warned appropriately if the URL is missing.
        href = opt[:href].freeze

        # Grab the name of the source file that can be optionally embeded with %1
        # which will increment for each frame (e.g. video%1.jpg becomes video1.jpg,
        # video2.jpg etc. up to the total number of frames).  The original source
        # image name is frozen to ensure it isn't modified later.
        src = opt[:src].freeze

        # This will hold all frame source file names interpolated to include
        # index (e.g. %1 being replaced with the frame number, if present).
        frames = []

        # For each frame, create a fully-qualified image source and
        # add it to the frame list.
        frame_count = (opt[:frames] || 1).to_i

        # True if the video clip will animate using smooth fading
        # between several frames of the video.
        has_animation = frame_count > 1

        # Iterate through the frames and replace %1 with the frame number.
        # this loop also verifies that the referenced image exists.
        frame_count.times do |n|
          frame_src = src.gsub('%1', "#{n + 1}")
          frames << image_url(frame_src, opt, ctx, false, false)
        end

        # Grab the first fully-qualified frame
        first_frame = frames[0]

        # Duration of the animated frame cycling, if multiple frames are provided.
        duration = (opt[:duration] || 15).to_i

        # Desired dimensions of the video clip.
        width = opt[:width].to_i
        height = opt[:height].to_i
        ctx.error("Video preview #{uid} is missing dimensions", { :width => width, :height => height, :src => src, :href => href }) unless width > 0 && height > 0

        # Calculate the scaled width for the left-side of the table
        # which is a crafty way to preserve the aspect ratio of the
        # video while it still fluidly scales.
        scaled_width = (width * SCALE).round

        # Background color and edge gradient - which defaults to a darker
        # version of the background color if not specified.
        bgcolor = detect_bgcolor(opt, '#5b5f66')
        gradient = opt[:gradient] || Util::darken(bgcolor, 0.25)

        # This is the name of the class applied to the anchor tag
        # to animate the hover.
        hover_klass = 'video'
        play_button_klass = 'play-button'

        # This is the name of the animation, if any, that will be
        # assigned to the table and defined in the CSS.
        animation_name = "#{hover_klass}#{uid}-frames"

        # Size calculations based on the specified arrow size or
        # the defaulted 30px arrow.  The border_* variables control
        # the circular border around the play arrow.
        play_arrow_size = (opt[PLAY_ARROW_SIZE] || 30).to_i
        play_arrow_height = (play_arrow_size * 0.5666).round
        play_border_radius = (play_arrow_size * 1.1333).round
        play_border_top_bottom = (play_arrow_size * 0.6).round
        play_border_right = (play_arrow_size * 0.5333).round
        play_border_left = (play_arrow_size * 0.8).round

        html = []
        html << '<!--[if !vml]-->'

        # Using an Element to produce the appropriate anchor helper with
        # the desired
        html << Element.new('a', { :id => id, :href => href, :class => hover_klass, :bgcolor => bgcolor, :bggradient => gradient, :block => true }).to_helper

        table = Element.new('table', {
                :width => '100%', :background => first_frame, BACKGROUND_SIZE => 'cover',
                Table::TR_TRANSITION => %q("all .5s cubic-bezier(0.075, 0.82, 0.165, 1)")
            })
        table[:animation] = %Q("#{animation_name} #{duration}s ease infinite") if has_animation
        html << table.to_helper

        # Transparent spacer for preserving aspect ratio.
        spacer_image_name = "vp-#{scaled_width}x#{height}.png"
        spacer_image = File.join(ctx.email.image_dir, spacer_image_name)

        # Test if the file exists
        unless File.exist?(spacer_image)

          # Requiring on-demand, don't load chunky_png unless the user has
          # started using video_preview.
          require 'chunky_png'

          # Creating an image from scratch, save as an interlaced PNG
          png = ChunkyPNG::Image.new(scaled_width, height, ChunkyPNG::Color::TRANSPARENT)
          png.save(spacer_image, :interlace => true)

        end

        # Assembling the first <td> which manages the aspect ratio of the
        # video as a separate string to avoid unnecessary line breaks in
        # the resulting HTML.
        aspect_ratio_td = Element.new('td', :width => '25%').to_helper
        aspect_ratio_td << Element.new('img', { :src => ctx.image_url(spacer_image_name), :alt => quote(''), :width => '100%', :border => 0,
                :style => { :height => :auto, :display => :block, :opacity => 0, :visibility => :hidden } }).to_s
        aspect_ratio_td << '{/td}'
        html << aspect_ratio_td

        # Center column holds the CSS-based arrow
        html << Element.new('td', :width => '50%', :align => :center, :valign => :middle).to_helper

        # These are the arrow and circle border, respectively.  Not currently
        # configurable in terms of size or color.
        html << %Q(<div class="#{play_button_klass}" style="background-image: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.1)); border: 4px solid white; border-radius: 50%; box-shadow: 0 1px 2px rgba(0,0,0,0.3), inset 0 1px 2px rgba(0,0,0,0.3); height: #{px(play_border_radius)}; margin: 0 auto; padding: #{px(play_border_top_bottom)} #{px(play_border_right)} #{px(play_border_top_bottom)} #{px(play_border_left)}; transition: transform .5s cubic-bezier(0.075, 0.82, 0.165, 1); width: #{px(play_border_radius)};">)
        html << %Q(<div style="border-color: transparent transparent transparent white; border-style: solid; border-width: #{px(play_arrow_height)} 0 #{px(play_arrow_height)} #{px(play_arrow_size)}; display: block; font-size: 0; height: 0; Margin: 0 auto; width: 0;">&nbsp;</div>)
        html << '</div>'

        html << '{/td}'
        html << '{td width=25%}&nbsp;{/td}'
        html << '{/table}'
        html << '{/a}'

        # Pre-loading the images prevents a flash that can occur because the
        # browser only loads the frames once the animation demands them.
        if has_animation && !opt[NO_PRELOAD]
          all_frames = frames.collect { |f| %Q(url(#{f})) }.join(',')
          html << Element.new('div', :style => { BACKGROUND_IMAGE => %Q(#{all_frames}), :display => 'none' }).to_s + '</div>'
        end

        # Concludes the if [if !vml] section targeting non-outlook.
        html << '<![endif]-->'

        # Calculations necessary to render the play arrow in VML.
        outlook_arrow_size = (play_arrow_size * 2.6).round
        outlook_arrow_width = (play_arrow_size * 1.0666).round
        outlook_arrow_height = (play_arrow_size * 0.5333).round
        outlook_arrow_left = width / 2 - play_arrow_size / 2
        outlook_arrow_top = height / 2 - play_arrow_size / 2
        outlook_border_left = width / 2 - outlook_arrow_size / 2
        outlook_border_top = height / 2 - outlook_arrow_size / 2

        # Use the link central processing routine to ensure a viable link has
        # been provided and tag/track it from Outlook.
        outlook_id, outlook_href, target_blank = Link.process(id, href, false, ctx)

        # Check for the outlook-src attribute which will be used in place of
        # the first frame if it is specified.
        outlook_src = opt[OUTLOOK_SRC]
        outlook_src = outlook_src.blank? ? first_frame : image_url(outlook_src, opt, ctx, false, false)

        html << '<!--[if vml]>'
        html << %Q(<v:group xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" coordsize="#{width},#{height}" coordorigin="0,0" href="#{outlook_href}" style="width:#{width}px;height:#{height}px;">)
        html << %Q(<v:rect fill="t" stroked="f" style="position:absolute;width:#{width};height:#{height};"><v:fill src=\"#{outlook_src}\" type="frame"/></v:rect>)
        html << %Q(<v:oval fill="t" strokecolor="white" strokeweight="4px" style="position:absolute;left:#{outlook_border_left};top:#{outlook_border_top};width:#{outlook_arrow_size};height:#{outlook_arrow_size}"><v:fill color="black" opacity="30%"/></v:oval>)
        html << %Q(<v:shape coordsize="#{play_border_left},#{outlook_arrow_width}" path="m,l,#{outlook_arrow_width},#{play_border_left},#{outlook_arrow_height},xe" fillcolor="white" stroked="f" style="position:absolute;left:#{outlook_arrow_left};top:#{outlook_arrow_top};width:#{play_arrow_size};height:#{play_arrow_size};"/>)
        html << '</v:group>'
        html << '<![endif]-->'

        # Will hold any CSS styles, if there are some necessary
        # to inject into the email.
        styles = []

        # If this is the first video clip in the email, we need
        # to include the general styles shared across all clips.
        if uid == 1
          styles << ".#{hover_klass}:hover .#{play_button_klass} {"
          styles << '  transform: scale(1.1);'
          styles << '}'
          styles << ".#{hover_klass}:hover tr {"
          styles << '  background-color: rgba(255, 255, 255, .2);'
          styles << '}'
        end

        # If this video clip has animation, then we need to include
        # the keyframes necessary to smoothly animate between each.
        if has_animation

          # The time spent in each frame is based on a weighted distribution
          # of frames vs. transition time between frames.
          total_weight = ((FRAME_WEIGHT * frame_count) + (TRANSITION_WEIGHT * frame_count)).to_f
          percent_per_frame = (FRAME_WEIGHT / total_weight * 100.0).round
          percent_per_transition = (TRANSITION_WEIGHT / total_weight * 100.0).round

          # This will hold the total percentage as we increment toward the
          # end of the animation.
          percent = 0.0

          keyframes = Animation::Keyframes.new(animation_name, ctx)

          # Iterate through each frame and add two keyframes, the first
          # being the time at which the frame appears plus another frame
          # after the duration it should be on screen.
          frames.each do |f|
            this_frame_url = "url(#{f})"

            keyframes.add_keyframe(percent, { BACKGROUND_IMAGE => this_frame_url })
            percent += percent_per_frame
            keyframes.add_keyframe(percent, { BACKGROUND_IMAGE => this_frame_url })
            percent += percent_per_transition

          end

          # Transition back to the first frame.
          keyframes.add_keyframe(100, { BACKGROUND_IMAGE => "url(#{first_frame})" })

          # Add the keyframes to the styles array.
          styles << keyframes.to_s

        end

        # Add the styles to the email's header
        ctx.styles << styles.join("\n") unless styles.blank?

        html.join("\n")

      end

      private

      # Name of the attribute that controls the size of the play button arrow.
      PLAY_ARROW_SIZE = :'play-size'

      # Name of the boolean attribute that can be provided to disable the
      # preloading of images in an animation.
      NO_PRELOAD = :'no-preload'

      # Constants defining the weight of a frame relative to the weight of
      # the transition.  In this case, 2-to-1 means each frame will be on
      # the screen for twice as long as it takes to transition between
      # them.
      FRAME_WEIGHT = 2.0
      TRANSITION_WEIGHT = 1.0

      # Scale applied to the width of the image to preserve the aspect
      # ratio of the video that fluidly scales on mobile devices.
      SCALE = 0.25

    end
  end
end

