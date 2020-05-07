module Api
  module V1x2
    class TemplatesController < ApplicationController
      include Mixins::IndexMixin

      def show
        template = Template.find(params.require(:id))
        authorize template

        json_response(template)
      end

      def index
        collection(policy_scope(Template))
      end
    end
  end
end
