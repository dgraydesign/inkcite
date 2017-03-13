module Inkcite
  module PostProcessor

    def post_process html, ctx
      raise 'Extending class must implement process(html, ctx)'
    end

    def self.run_all html, ctx
      ctx.post_processors.inject(html) { |h, pp| pp.post_process(h, ctx) }
    end

  end
end
