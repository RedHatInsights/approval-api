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

        RBAC::Access.enabled? ? collection(rbac_scope(templates)) : collection(templates)
      end

      private

      def rbac_scope(relation)
        access_obj = RBAC::Access.new('templates', 'read').process
        raise Exceptions::NotAuthorizedError, "Not Authorized to list templates" unless access_obj.accessible? || access_obj.admin?

        relation
      end
    end
  end
end
