module Api
  module V1x0
    class TemplatesController < ApplicationController
      include Mixins::IndexMixin

      def show
        template = Template.find(params.require(:id))
        json_response(template)
      end

      def index
        templates = Template.all
        collection(templates)
      end
    end
  end
end
