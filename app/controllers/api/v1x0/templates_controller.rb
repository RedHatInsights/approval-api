module Api
  module V1x0
    class TemplatesController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]
      before_action :index_access_check, :only => %i[index]

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
