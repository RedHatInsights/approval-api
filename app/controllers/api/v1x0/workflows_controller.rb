module Api
  module V1x0
    class WorkflowsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::RBACMixin

      before_action :create_access_check, :only => %i[create]
      before_action :update_access_check, :only => %i[update]
      before_action :destroy_access_check, :only => %i[destroy]

      def create
        workflow = WorkflowCreateService.new(params.require(:template_id)).create(workflow_params)
        json_response(workflow, :created)
      end

      # TODO: remove 'approval:workflows:read' from approver acls list in RBAC Insight
      def show
        raise Exceptions::NotAuthorizedError, "Not Authorized for workflows" if RBAC::Access.enabled? && !admin?

        json_response(Workflow.find(params.require(:id)))
      end

      def index
        relation = if params[:template_id]
                     template = Template.find(params.require(:template_id))
                     template.workflows
                   else
                     Workflow.all
                   end

        collection(index_scope(relation))
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

      def link
        WorkflowLinkService.new(params.require(:id)).link(attrs)

        head :no_content
      end

      def unlink
        WorkflowUnlinkService.new(params[:id]).unlink(attrs)

        head :no_content
      end

      def resolve
        found_workflows = WorkflowFindService.new.find(attrs)
        found_workflows.empty? ? head(:no_content) : json_response(found_workflows, :ok)
      end

      def update
        workflow = Workflow.find(params.require(:id))
        WorkflowUpdateService.new(workflow.id).update(workflow_params)

        json_response(workflow)
      end

      private

      # TODO: remove 'approval:workflows:read' from approver acls list in RBAC Insight
      def rbac_scope(relation)
        raise Exceptions::NotAuthorizedError, "Not Authorized for #{relation.model.table_name}" unless admin?

        relation
      end

      def workflow_params
        params.permit(:id, :object_id, :object_type, :app_name, :name, :description, :template_id, :group_refs => [])
      end

      def attrs
        workflow_params.slice(:object_id, :object_type, :app_name).to_unsafe_h
      end
    end
  end
end
