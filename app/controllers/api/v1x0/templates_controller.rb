module Api
  module V1x0
    class TemplatesController < ApplicationController
      include Mixins::IndexMixin

      def show
        template = policy_scope(Template).find(params.require(:id))
        json_response(template)
      end

      def index
        collection(policy_scope(Template))
      end
    end
  end
end
