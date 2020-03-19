module Api
  module V1x0
    class TemplatesController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin
      include Api::V1x0::Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]

      def show
        template = Template.find(params.require(:id))
        json_response(template)
      end

      def index
        templates = Template.all

        collection(index_scope(templates))
      end

      def rbac_scope(relation)
        relation
      end
    end
  end
end
