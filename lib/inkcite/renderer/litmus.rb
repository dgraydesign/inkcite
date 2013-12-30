module Inkcite
  module Renderer
    class Litmus < Base

      def render tag, opt, ctx

        # Litmus tracking is enabled only for production emails.
        return nil unless ctx.production? && ctx.email?

        code = opt[:code] || opt[:id]
        return nil if code.blank?

        merge_tag = opt[MERGE_TAG] || ctx[MERGE_TAG]

        ctx.styles << "@media print{#_t { background-image: url('https://#{code}.emltrk.com/#{code}?p&d=#{merge_tag}');}}"
        ctx.styles << "div.OutlookMessageHeader {background-image:url('https://#{code}.emltrk.com/#{code}?f&d=#{merge_tag}')}"
        ctx.styles << "table.moz-email-headers-table {background-image:url('https://#{code}.emltrk.com/#{code}?f&d=#{merge_tag}')}"
        ctx.styles << "blockquote #_t {background-image:url('https://#{code}.emltrk.com/#{code}?f&d=#{merge_tag}')}"
        ctx.styles << "#MailContainerBody #_t {background-image:url('https://#{code}.emltrk.com/#{code}?f&d=#{merge_tag}')}"

        ctx.footer << '<div id="_t"></div>'
        ctx.footer << "<img src=\"https://#{code}.emltrk.com/#{code}?d=#{merge_tag}\" width=1 height=1 border=0 />"

        nil
      end

      private

      MERGE_TAG = :'litmus-merge-tag'

    end
  end
end
