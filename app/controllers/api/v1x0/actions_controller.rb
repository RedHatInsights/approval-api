module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin

      def index
        collection(policy_scope(Action))
      end

      def show
        action = Action.find(params.require(:id))
        authorize action

        json_response(action)
      end

      def create
        authorize Action

        # make sure have permission to read the request
        req = Request.find(params.require(:request_id))
        authorize(req, 'show?')

        action = ActionCreateService.new(params.require(:request_id)).create(params_for_create)
        json_response(action, :created)
      end
    end
  end
end
