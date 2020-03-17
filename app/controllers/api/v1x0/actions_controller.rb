module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin

      def index
        req = Request.find(params.require(:request_id))

        collection(policy_scope(req.actions))
      end

      def show
        authorize Action

        action = Action.find(params.require(:id))
        json_response(action)
      end

      def create
        authorize Action

        action = ActionCreateService.new(params.require(:request_id)).create(params_for_create)
        json_response(action, :created)
      end
    end
  end
end
