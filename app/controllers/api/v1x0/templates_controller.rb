module Api
  module V1x0
    class TemplatesController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :read_access_check, :only => %i[show]

      def show
        template = Template.find(params.require(:id))
        json_response(template)
      end

      def index
        templates = Template.all

        RBAC::Access.enabled? ? collection(rbac_scope(templates)) : collection(templates)
      end

      private

      def rbac_scope(relation)
        rbac_read_access(relation)

        relation
      end
    end
  end
end
