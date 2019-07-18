module Api
  module V1x0
    class WorkflowsController < ApplicationController
      include Mixins::IndexMixin

      def create
        workflow = WorkflowCreateService.new(params.require(:template_id)).create(workflow_params)
        json_response(workflow, :created)
      end

      def show
        workflow = Workflow.find(params.require(:id))

        json_response(workflow)
      end

      def index
        relation = if params[:template_id]
          template = Template.find(params.require(:template_id))
          template.workflows
        else
          Workflow.all
        end

        RBAC::Access.enabled? ? collection(rbac_scope(relation)) : collection(relation)
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

      def rbac_scope(relation)
        access_obj = RBAC::Access.new('workflows', 'read').process
        raise Exceptions::NotAuthorizedError, "Not Authorized to list workflows" unless access_obj.accessible? || access_obj.admin?

        relation
      end
    end
  end
end
