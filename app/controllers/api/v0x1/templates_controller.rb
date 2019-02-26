module Api
  module V0x1
    class TemplatesController < ApplicationController
      def show
        template = Template.find(params.require(:id))
        json_response(template)
      end

      def index
        templates = Template.all
        json_response(templates)
      end
    end
  end
end
