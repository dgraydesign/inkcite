module Inkcite
  module Renderer
    class Link < ContainerBase

      def render tag, opt, ctx

        tag_stack = ctx.tag_stack(:a)

        if tag == '/a'

          # Grab the attributes of the opening tag.
          opening = tag_stack.pop

          # Nothing to do in the
          return '' if ctx.text?

          html = '</a>'

          # Check to see if the declaration has been marked as a block
          # element and if so, close the div.
          html << '</div>' if opening[:block]

          return html
        end

        # Push the link's options onto the tag stack so that we can have
        # access to its attributes when we close it.
        tag_stack << opt

        # Get the currently open table cell and see if link color is
        # overridden in there.
        td_parent = ctx.tag_stack(:td).opts
        table_parent = ctx.tag_stack(:table).opts

        # Choose a color from the parameters or inherit from the parent td, table or context.
        opt[:color] = detect(opt[:color], td_parent[:link], table_parent[:link], ctx[LINK_COLOR])

        a = Element.new('a')

        # Mixes the attributes common to all container elements
        # including font, background color, border, etc.
        mix_all a, opt, ctx

        id = opt[:id]
        href = opt[:href]

        # If a URL wasn't provided in the HTML, then check to see if there is
        # a link declared in the project's links_tsv file.  If so, we need to
        # duplicate it so that tagging doesn't get applied multiple times.
        if href.blank?
          links_tsv_href = ctx.links_tsv[id]
          href = links_tsv_href.dup unless links_tsv_href.blank?
        end

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

            ctx.error 'Link missing href', { :id => id } unless last_href

          else

            # Ensure the validity of the URL in the link to prevent problems -
            # e.g. unexpected carriage return in the href.
            ctx.error('Link href appears to be invalid', { :id => id, :href => href }) unless opt[:force] || valid?(href)

            # Optionally tag the link's query string for post-send log analytics.
            href = add_tagging(id, href, ctx)

            if last_href.blank?

              # Associate the href with it's ID in case we bump into this link again.
              ctx.links[id] = href

            elsif last_href != href

              # It saves everyone a lot of time if you alert them that an ID appears multiple times
              # in the email and with mismatched URLs.
              ctx.error 'Link href mismatch', { :id => id, :expected => last_href, :found => href }

            end

          end

          # Optionally replace the href with an ESP trackable url.  Gotta do this after
          # the link has been stored in the context because we don't want trackable
          # URLs interfering with the links file.
          href = add_tracking(id, href, ctx)

          a[:target] = BLANK

        end

        # Make sure that these types of links have quotes.
        href = quote(href) unless ctx.text?

        # Set the href attribute to the resolved href.
        a[:href] = href

        # Links never get any text decoration.
        a.style[TEXT_DECORATION] = NONE

        # Force the display: block attribute if the boolean block parameter has
        # been specified.
        a.style[:display] = :block if opt[:block]

        if ctx.browser?

          # Programmatically we can install onclick listeners for hosted versions.
          # Check to see if one is specified and the Javascript is permitted in
          # this version.
          onclick = opt[:onclick]
          a[:onclick] = quote(onclick) unless onclick.blank?

        end

        html = ''

        if ctx.text?
          html << a[:href]

        else

          klass = opt[:class]
          a.classes << klass unless klass.blank?

          mix_responsive a, opt, ctx

          # Some responsive modes (e.g. button) change the display type from in-line
          # to block.  This change can cause unexpected whitespace or other unexpected
          # layout changes.  Outlook doesn't support block display on link elements
          # so the best workaround is simply to wrap the element in <div> tags.
          if a.responsive_styles.any?(&:block?)
            html << '<div>'

            # Remember that we made this element block-display so that we can append
            # the extra div when we close the tag.
            opt[:block] = true

          end

          html << a.to_s

        end

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
            Util::add_query_param(href, replace_tag(tag, id, ctx))
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

      # Tests whether or not the href provided is a valid http(s) link.
      # Courtest http://stackoverflow.com/questions/7167895/whats-a-good-way-to-validate-links-urls-in-rails
      def valid? url
        begin
          uri = URI.parse(url)
          uri.kind_of?(URI::HTTP)
        rescue URI::InvalidURIError
          false
        end
      end

    end
  end
end
