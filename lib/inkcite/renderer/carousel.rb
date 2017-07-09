module Inkcite
  module Renderer

    # Interactive image carousel based on FreshInbox's technique
    # http://freshinbox.com/resources/tools/carousel/
    #
    # Usage:
    #
    # {carousel width=450 height=280 href="..."}
    # 	{carousel-img id="..." src="..."}
    # 	{carousel-img id="..." src="..." href="..."}
    # 	{carousel-img id="..." src="..."}
    # {/carousel}
    #
    class Carousel < ContainerBase

      class Image < ImageBase

        def render tag, opt, ctx

          # Get a reference to the tag stack that contains these frames
          tag_stack = ctx.tag_stack :carousel

          # Get the opts held by the parent carousel.
          carousel_opt = tag_stack.opts

          #opt[:_src] = image_url(opt[:src], opt, ctx, false, false)

          # Initialize the frames array
          carousel_opt[:frames] << opt

          nil
        end

      end

      def render tag, opt, ctx

        html = []

        # Get a reference to the tag stack
        tag_stack = ctx.tag_stack :carousel

        # All the rendering heavylifting is done when the closing tag is encountered
        # meaning we've indexed each of the carousel-img entries between it and the
        # opening tag.
        if tag == '/carousel'

          # Remove the previously opened opts from the tag stack.
          open_opt = tag_stack.pop

          # Unique ID of this carousel to uniquely identify the classes
          uuid = open_opt[:uuid]

          # Link ID prefix
          carousel_id = open_opt[:id]

          # Width of the primary image
          width = open_opt[:width].to_i
          height = open_opt[:height].to_i
          ctx.error('Missing carousel dimensions', { :id => carousel_id, :width => width, :height => height }) if height <= 0 || width <= 0

          # Grab the array of frames and count the total number of frames.
          frames = open_opt[:frames]
          total_frames = frames.count

          # This {table} Helper wraps the entire carousel.
          table = Element.new('table', :width => width, :class => 'crsl', :mobile => :fill)

          # Determine if a background color for the entire carousel has been specified
          # using either bgcolor or background-color.  If so, pass it on to the table Helper.
          bgcolor = detect_bgcolor(open_opt)
          table[:bgcolor] = quote(bgcolor) unless none?(bgcolor)

          html << table.to_helper

          td = Element.new('td')
          mix_font td, open_opt, ctx
          html << td.to_s

          html << %q({not-outlook})
          html << %q(<input type=radio class="crsl-radio" style="display:none !important;" checked>)
          html << %q({/not-outlook})

          # Div to hold the carousel contents.
          html << %q({div})

          html << %q({not-outlook})
          html << Element.new('div', :class => %Q("crsl-wrap crsl-#{uuid}"), :style => {
                  :width => pct(100), :height => px(0), MAX_HEIGHT => px(0), :overflow => :hidden, TEXT_ALIGN => :center
              }).to_s

          # Array of hidden radio buttons that manage which thumbnail is selected.
          total_frames.times do |n|
            box_index = total_frames - n

            html << %q(<label>)
            html << %Q(<input type="radio" name="crsl#{uuid}" class="crsl-radio-#{box_index}" style="display:none !important;"#{' checked' if box_index == 1}>)
            html << %q(<span>)

          end

          total_frames.times do |n|
            box_index = n + 1
            frame_opt = frames[n]
            frame_id = frame_opt[:id] || "#{carousel_id}-#{box_index}"

            href = frame_opt[:href] || open_opt[:href]
            src = frame_opt[:src]

            caption = frame_opt[:caption]
            alt = frame_opt[:alt] || caption

            html << %Q(<div class="crsl-content-#{box_index} crsl-content">)
            html << %Q({a id="#{frame_id}" href="#{href}"}) unless href.blank?
            html << %Q({img src="#{src}" width=#{width} height=#{height} alt="#{alt}" max-height=0 mobile="fill"})
            html << %q({/a}) unless href.blank?

            unless caption.blank?
              caption_div = Element.new('div', :class => 'crsl-caption')
              mix_font caption_div, open_opt, ctx
              html << caption_div.to_s
              html << caption
              html << "</div>"
            end

            html << %q(</div>)

          end

          thumbnail_width = 50
          thumnail_height = (thumbnail_width / width) * height.round(0)

          total_frames.times do |n|
            box_index = total_frames - n
            frame_opt = frames[n]

            src = frame_opt[:src]

            html << %q(<span class="crsl-thumb" style="display:none;">)
            html << %Q({img src="#{src}" width=#{width} height=#{height} max-height=0})
            html << %q(</span>)
            html << %q(</span>)
            html << %q(</label>)

          end

          html << %q(</div>)
          html << %q({/not-outlook})

          # Fallback
          fallback_frame_opt = frames[0]
          fallback_href = fallback_frame_opt[:href] || open_opt[:href]
          fallback_src = open_opt[OUTLOOK_SRC] || fallback_frame_opt[:src]

          html << %q(<div class="fallback"><div class="crsl-content">)
          html << %Q({a id="#{carousel_id}" href="#{fallback_href}"}{img src="#{fallback_src}" width=#{width} height=#{height} alt="#{open_opt[:alt]}" mobile="fill"}{/a})
          html << %q(</div></div>)

          html << '{/div}'
          html << '{/td}'
          html << '{/table}'

          styles = []

          if uuid == 1

            styles << Inkcite::Renderer::Style.new('input', ctx, { :display => :none })

            styles << Inkcite::Renderer::Style.new('.crsl-radio:checked + * .crsl-wrap', ctx, { :'height' => 'auto !important', MAX_HEIGHT => 'none !important;', :'line-height' => 0 })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap span', ctx, { :'font-size' => 0, :'line-height' => 0 })

            styles << Inkcite::Renderer::Style.new('.crsl-radio:checked + * .crsl-wrap .crsl-content', ctx, { :'display' => 'none', MAX_HEIGHT => px(0), :'overflow' => 'hidden' })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap .crsl-thumb', ctx, { :cursor => 'pointer', :display => 'inline-block !important', :width => '17.5%', :margin => '1% 0.61%', :border => "2px solid #{DEFAULT_BORDER_COLOR}" })

            # hide for thunderbird as it doesn't support checkboxes
            styles << Inkcite::Renderer::Style.new('.moz-text-html .crsl-thumb', ctx, { :display => 'none !important' })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap .crsl-thumb:hover', ctx, { :border => "2px solid #{DEFAULT_HOVER_COLOR}" })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap input:checked + span > span', ctx, { BORDER_COLOR => DEFAULT_HOVER_COLOR })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap .crsl-thumb img', ctx, { :width => '100%', :height => 'auto' })

            styles << Inkcite::Renderer::Style.new('.crsl-wrap img', ctx, { MAX_HEIGHT => 'none !important' })

            styles << Inkcite::Renderer::Style.new('.crsl-radio:checked + * .fallback', ctx, { :display => 'none !important', MAX_HEIGHT => px(0), :height => px(0), :overflow => 'hidden' })

          end

          # Configurable border color
          border_color = open_opt[BORDER_COLOR]
          unless border_color.blank?
            border_color = hex(border_color)
            styles << Inkcite::Renderer::Style.new(".crsl-#{uuid} .crsl-thumb", ctx, { BORDER_COLOR => border_color }) if DEFAULT_BORDER_COLOR != border_color
          end

          # Configurable hover color
          hover_color = open_opt[:'hover-color']
          unless hover_color.blank?
            hover_color = hex(hover_color)
            if DEFAULT_HOVER_COLOR != hover_color
              styles << Inkcite::Renderer::Style.new(".crsl-#{uuid} input:checked + span > span", ctx, { BORDER_COLOR => hover_color })
              styles << Inkcite::Renderer::Style.new(".crsl-#{uuid} .crsl-thumb:hover", ctx, { BORDER_COLOR => hover_color })
            end
          end

          frame_checked_style_name = total_frames.times.collect { |n| ".crsl-wrap .crsl-radio-#{n + 1}:checked + span .crsl-content-#{n + 1}" }.join(",\n")
          styles << Inkcite::Renderer::Style.new(frame_checked_style_name, ctx, { :display => 'block !important', MAX_HEIGHT => 'none !important', :overflow => 'visible !important' })

          ctx.styles << styles.join("\n") unless styles.blank?


        else

          # Get a unique ID for this carousel
          opt[:uuid] = uuid = ctx.unique_id :carousel

          # Confirm that a unique ID prefix has been provided by the designer or
          # inherit one from the unique count.
          opt[:id] = "crsl#{uuid}" if opt[:id].blank?

          # Initialize the array of frames that will be collected and
          # assembled when this carousel close tag is encountered.
          opt[:frames] = []

          # Push this carousel onto the stack as the parent of the
          # frames that will be enclosed.
          tag_stack << opt

        end

        html.join("\n")
      end

      private

      DEFAULT_HOVER_COLOR = '#444444'
      DEFAULT_BORDER_COLOR = '#bbbbbb'

    end
  end
end
