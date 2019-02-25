module Api
  module V0x1
    class ActionsController < ApplicationController
      def index
        stage = Stage.find(params.require(:stage_id))
        json_response(stage.actions)
      end

      def show
        action = Action.find(params.require(:id))

        json_response(action)
      end

      def create
        action = ActionCreateService.new(params.require(:stage_id)).create(action_params)
        json_response(action, :created)
      end

      private

      def action_params
        params.permit(:operation, :processed_by, :comments)
      end
    end
  end
end
