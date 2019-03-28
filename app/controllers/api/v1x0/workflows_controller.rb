module Api
  module V1x0
    class WorkflowsController < ApplicationController
      include Mixins::IndexMixin

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
          collection(template.workflows)
        else
          workflows = Workflow.all
          collection(workflows)
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
        params.permit(:name, :description, :limit, :offset, :group_ids => [])
      end
    end
  end
end
