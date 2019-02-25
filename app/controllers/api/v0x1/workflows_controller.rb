module Api
  module V0x1
    class WorkflowsController < ApplicationController
      def create
        workflow = WorkflowCreateService.new(params.require(:template_id)).create(workflow_params)
        json_response(workflow, :created)
      rescue ActiveRecord::RecordNotFound => e
        json_response({ :message => e.message }, :unprocessable_entity)
      end

      def show
        workflow = Workflow.find(params.require(:id))

        json_response(workflow)
      end

      def index
        if params[:template_id]
          template = Template.find(params.require(:template_id))
          json_response(template.workflows)
        else
          workflows = Workflow.all
          json_response(workflows)
        end
      end

      def destroy
        Workflow.find(params.require(:id)).destroy

        head :no_content
      end

      def update
        Workflow.find(params.require(:id)).update(workflow_params)

        head :no_content
      end

      private

      def workflow_params
        params.permit(:name, :description, :group_ids => [])
      end
    end
  end
end
