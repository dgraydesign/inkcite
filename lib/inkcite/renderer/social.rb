module Inkcite
  module Renderer
    class Social < Base

      class Facebook < Social

        def initialize
          super(:src => 'facebook.png', :alt => 'Facebook', :cta => 'Share')
        end

        protected

        def get_share_href url, text, opts, ctx
          %Q(https://www.facebook.com/sharer/sharer.php?u=#{url}&t=#{text})
        end

      end

      class Pintrest < Social

        def initialize
          super(:src => 'pintrest.png', :alt => 'Pintrest', :cta => 'Pin it', :color => '#CB2027')
        end

        protected_methods

        def get_share_href url, text, opts, ctx

          media = opts.delete(:media).to_s
          ctx.error("Pintrest sharing 'media' attribute can't be blank", :id => opts[:id]) if media.blank?

          %Q(https://www.pinterest.com/pin/create/button/?url=#{url}&media=#{URI.escape(media)}&description=#{text})
        end

      end

      class Twitter < Social

        def initialize
          super(:src => 'twitter.png', :alt => 'Twitter', :cta => 'Tweet', :scale => 81 / 100.0)
        end

        protected

        def get_share_href url, text, opts, ctx
          %Q(https://twitter.com/share?url=#{url}&text=#{text})
        end

      end

      def initialize defaults
        @defaults = defaults

        # Ensure a default scale of 1:1 is installed into the defaults
        # if one is not otherwise provided.
        @defaults[:scale] ||= 1.0

      end

      def render tag, opts, ctx

        # Ensure that the sharing icon exists in the project.
        ensure_icon_exists ctx

        height = (opts.delete(:size) || opts.delete(:height) || 15).to_i
        width = (height / @defaults[:scale]).round

        id = opts[:id]

        share_url = opts.delete(:href).to_s
        ctx.error("Social sharing 'href' attribute can't be blank", :tag => tag, :id => id) if share_url.blank?

        share_text = opts.delete(:text).to_s
        ctx.error("Social sharing 'text' attribute can't be blank", :tag => tag, :id => id, :href => share_url) if share_text.blank?

        # Let the extending class format the fully-qualified URL to the sharing service.
        service_href = get_share_href URI.escape(share_url), URI.escape(share_text), opts, ctx

        # Check to see if there is a special color for this link (e.g. Pintrest) or
        # if it has been specified by the caller.
        opts[:color] ||= @defaults[:color]

        # Force the font size and line height to match the size of the
        # icon being used - this ensures proper vertical middle alignment.
        opts[FONT_SIZE] = height
        opts[LINE_HEIGHT] = height

        %Q({a href="#{service_href}" #{Renderer.join_hash(opts)}}{img src=#{@defaults[:src]} height=#{height} width=#{width} display=inline alt="#{@defaults[:alt]}"} #{@defaults[:cta]}{/a})

      end

      protected

      def ensure_icon_exists ctx

        src = @defaults[:src]

        # Get the full destination path to the icon in the current project.  If
        # the icon already exists, then there is nothing left to do.
        dest_icon_path = ctx.email.image_path(src)
        return if File.exists?(dest_icon_path)

        # Get the full path to the source icon bundled with Inkcite.
        source_icon_path = File.join(Inkcite.asset_path, 'social', src)

        # Ensure that the images/ directory exists in the project, then copy
        # the image into it.
        FileUtils.mkpath(ctx.email.image_dir)
        FileUtils.cp(source_icon_path, dest_icon_path)

      end

      def get_share_href url, text, opts, ctx
        raise NotImplementedError
      end

    end
  end
end
