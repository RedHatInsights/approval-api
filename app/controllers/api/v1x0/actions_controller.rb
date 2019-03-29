module Api
  module V1x0
    class ActionsController < ApplicationController
      include Mixins::IndexMixin
      def index
        stage = Stage.find(params.require(:stage_id))
        collection(stage.actions)
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
        params.permit(:operation, :processed_by, :comments, :limit, :offset)
      end
    end
  end
end
