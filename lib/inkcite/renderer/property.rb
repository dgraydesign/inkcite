module Inkcite
  module Renderer
    class Property < Base

      def render tag, opt, ctx

        html = ctx[tag]
        if html.nil?
          ctx.error 'Unknown tag or property', { :tag => tag, :opt => "[#{opt.to_query}]" }
          return nil
        end

        # True if this is a opening tag - e.g. {feature ...}, not {/feature}
        is_open_tag = !tag.starts_with?(SLASH)

        # When a custom opening tag is encountered, if there is a corresponding
        # closing tag, we'll save the options provided at open so that they
        # can be pop'd by the closing tag and used in the closing HTML.
        if is_open_tag

          # Verify that a closing tag has been defined and push the opts
          # onto the stack.  No need to push opts and pollute the stack if
          # there is no closing tag to take advantage of them.
          close_tag = "#{SLASH}#{tag}"
          ctx.tag_stack(tag) << opt unless ctx[close_tag].blank?

        else

          # Chop off the forward slash to reveal the original open tag.  Then
          # grab the tag stack for said open tag.  Pop the most recently provided
          # opts off the stack so those values are available again.
          open_tag = tag[1..-1]
          tag_stack = ctx.tag_stack(tag[1..-1])

          # The provided opts take precedence over the ones passed to the open tag.
          opt = tag_stack.pop.merge(opt) if tag_stack

        end

        # Need to clone the property - otherwise, we modify the original property.
        # Which is bad.
        html = html.clone

        Parser.each html, VARIABLE_REGEX do |pair|

          # Split the declaration on the equals sign.
          variable, default = pair.split(EQUALS, 2)

          # Check to see if the variable has been defined in the parameters.  If so, use that
          # value - otherwise, inherit the default.
          (opt[variable.to_sym] || default).to_s

        end

      end

      private

      VARIABLE_REGEX = /\$([^\$]+)\$/

      DOLLAR = '$'
      EQUALS = '='
      SLASH = '/'

    end
  end
end
