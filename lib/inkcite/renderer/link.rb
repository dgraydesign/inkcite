module Inkcite
  module Renderer
    class Link < Responsive

      def render tag, opt, ctx

        return '</a>' if tag == '/a'

        a = Element.new('a')

        font_size = opt[FONT_SIZE]
        a.style[FONT_SIZE] = px(font_size) unless font_size.blank?

        line_height = opt[LINE_HEIGHT]
        a.style[LINE_HEIGHT] = px(line_height) unless line_height.blank?

        mix_text_shadow a, opt, ctx

        color = opt[:color]
        color = ctx[LINK_COLOR] if color.blank?
        a.style[:color] = hex(color) if !color.blank? && color != NONE

        id   = opt[:id]
        href = opt[:href]

        # True if the href is missing.  If so, we may try to look it up by it's ID
        # or we'll insert a default TBD link.
        missing = href.blank?

        # True if it's a link deeper into the content.
        hash = !missing && href.starts_with?(POUND_SIGN)

        # True if this is a mailto link.
        mailto = !missing && !hash && href.starts_with?(MAILTO)

        # Only perform special processing on the link if it's TBD or not a link to
        # something in the page.
        unless hash || mailto

          if id.blank?

            # Generate a placeholder ID and warn the user about it.
            id = "link#{ctx.links.size + 1}"
            ctx.error 'Link missing ID', { :href => href }

          else

            # Check to see if we've encountered an auto-incrementing link ID (e.g. event++)
            # Replace the ++ with a unique count for this ID prefix.
            id = id.gsub(PLUS_PLUS, ctx.unique_id(id).to_s) if id.end_with?(PLUS_PLUS)

          end

          # Get the HREF that we have previously encountered for this ID.  When not blank
          # we'll sanity check that the URL is the same.
          last_href = ctx.links[id]

          if missing

            # If we don't have a URL, check to see if we've encountered this
            href = last_href || ctx[MISSING_LINK_HREF]

            ctx.error "Link missing href", { :id => id } unless last_href

          else

            # Optionally tag the link's query string for post-send log analytics.
            href = add_tagging(id, href, ctx)

            if last_href.blank?

              # Associate the href with it's ID in case we bump into this link again.
              ctx.links[id] = href

            elsif last_href != href

              # It saves everyone a lot of time if you alert them that an ID appears multiple times
              # in the email and with mismatched URLs.
              ctx.error "Link href mismatch", { :id => id, :expected => last_href, :found => href }

            end

          end

          # Optionally replace the href with an ESP trackable url.  Gotta do this after
          # the link has been stored in the context because we don't want trackable
          # URLs interfering with the links file.
          href = add_tracking(id, href, ctx)

          a[:target] = BLANK

          # Make sure that these types of links have quotes.
          href = quote(href)

        end

        # Set the href attribute to the resolved href.
        a[:href] = href

        # Links never get any text decoration.
        a.style[TEXT_DECORATION] = NONE

        if ctx.browser?

          # Programmatically we can install onclick listeners for hosted versions.
          # Check to see if one is specified and the Javascript is permitted in
          # this version.
          onclick = opt[:onclick]
          a[:onclick] = quote(onclick) unless onclick.blank?

        end

        klass = opt[:class]
        a.classes << klass unless klass.blank?

        rule = mix_responsive a, opt, ctx

        html = a.to_s

        # If the responsive rule requires the link to be displayed
        # as a block, it needs to be treated as a block-style element
        # but "display: block;" doesn't work in Outlook.  So, wrap
        # it in <div>s instead.
        html = "<div>#{html}</div>" if rule && rule.block?

        html
      end

      private

      # Property controlling where missing links are pointed.
      MISSING_LINK_HREF = :'missing-link-url'

      # The configuration name of the field that holds the query parameter that
      # will be tacked onto the end of all links.
      TAG_LINKS = :'tag-links'

      # The configuration name of the field that holds the domain name(s) for
      # links that will be tagged.
      TAG_LINKS_DOMAIN = :'tag-links-domain'

      # The property name used to indicate that links in this email should be
      # replaced with [trackable URLs].
      TRACK_LINKS = :'track-links'

      # Value to open links in a new window.
      BLANK = '_blank'

      MAILTO = 'mailto:'

      # Signifies an auto-incrementing link ID.
      PLUS_PLUS = '++'

      def add_tagging id, href, ctx

        # Check to see if we're tagging links.
        tag = ctx[TAG_LINKS]
        unless tag.blank?

          # Blank tag domain means tag all the links - otherwise, make sure the
          # href matches the desired domain name.
          tag_domain = ctx[TAG_LINKS_DOMAIN]
          if tag_domain.blank? || href =~ /^https?:\/\/[^\/]*#{tag_domain}/

            # Prepend it with a question mark or an ampersand depending on the current
            # state of the lin.
            stag = href.include?('?') ? '&' : '?'
            stag << replace_tag(tag, id, ctx)

            # Inject before the pound sign if present - otherwise, just tack it on
            # to the end of the href.
            if hash = href.index(POUND_SIGN)
              href[hash..0] = stag
            else
              href << stag
            end

          end

        end

        href
      end

      def add_tracking id, href, ctx

        # Check to see if a trackable link string has been defined.
        tracking = ctx[Inkcite::Email::TRACK_LINKS]

        # Replace the fully-qualified URL with a tracking tag - presuming that the
        # ESP will replace this href with it's own trackable URL at deployment.
        href = URI.encode(replace_tag(tracking, id, ctx)) unless tracking.blank?

        href
      end

      def replace_tag tag, id, ctx

        # Inject the link's ID into the tag - that's the only value that can't
        # be resolved from the context.
        tag = tag.gsub('{id}', id)

        Inkcite::Renderer.render(tag, ctx)
      end

    end
  end
end
