module Api
  module V1x0
    class GroupsController < ApplicationController
      include Mixins::IndexMixin
      def create
        group = Group.create!(group_params)
        json_response(group, :created)
      end

      def group_operation
        GroupOperationService.new(params.require(:id)).operate(params.require(:operation), params.require(:parameters))
        head :no_content
      rescue StandardError => e
        json_response({ :message => e.message.to_s }, :forbidden)
      end

      def show
        group = Group.find(params.require(:id))
        json_response(group)
      end

      def index
        if params[:workflow_id]
          workflow = Workflow.find(params.require(:workflow_id))
          collection(workflow.groups)
        elsif params[:user_id]
          user = User.find(params.require(:user_id))
          collection(user.groups)
        else
          groups = Group.all
          collection(groups)
        end
      end

      def update
        Group.find(params.require(:id)).update(group_params)
        head :no_content
      end

      def destroy
        Group.find(params.require(:id)).destroy
        head :no_content
      end

      private

      def group_params
        params.permit(:name, :limit, :offset, :user_ids => [])
      end
    end
  end
end
