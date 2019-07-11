module Api
  module V1x0
    class WorkflowsController < ApplicationController
      include Mixins::IndexMixin

      def create
        workflow = WorkflowCreateService.new(params.require(:template_id)).create(workflow_params)
        json_response(workflow, :created)
      end

      def show
        if params.require(:id).to_s == "default"
          json_response(Workflow.default_workflow)
        else
          workflow = Workflow.find(params.require(:id))
          json_response(workflow)
        end
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
        workflow = Workflow.find(params.require(:id))
        workflow.destroy!
        head :no_content
      rescue ActiveRecord::InvalidForeignKey => e
        json_response({ :message => e.message }, :forbidden)
      rescue ActiveRecord::RecordNotDestroyed
        raise unless workflow.errors[:base].include?(Workflow::MSG_PROTECTED_RECORD)

        json_response({ :message => Workflow::MSG_PROTECTED_RECORD }, :forbidden)
      end

      def update
        workflow = Workflow.find(params.require(:id))
        workflow.update(workflow_params)

        json_response(workflow)
      end

      private

      def workflow_params
        params.permit(:name, :description, :group_refs => [])
      end
    end
  end
end
