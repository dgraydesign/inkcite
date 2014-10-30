module Inkcite
  module Renderer
    class Partial < Base

      def render tag, opt, ctx

        # Get the name of the file to include and then resolve the full
        # path to the file relative to the email's project directory.
        file_name = opt[:file]
        file = ctx.email.project_file(file_name)

        # Verify the file exists and route it through ERB.  Otherwise
        # let the designer know that the file is missing.
        if File.exist?(file)
          ctx.eval_erb(File.open(file).read, file_name)
        else
          ctx.error "Include not found", :file => file
        end

      end

    end
  end
end