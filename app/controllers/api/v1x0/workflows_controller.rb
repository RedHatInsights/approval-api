module Api
  module V1x0
    class WorkflowsController < ApplicationController
      include Mixins::IndexMixin

      def create
        authorize Workflow

        workflow = WorkflowCreateService.new(params.require(:template_id)).create(params_for_create)
        json_response(workflow, :created)
      end

      def show
        workflow = Workflow.find(params.require(:id))
        authorize workflow

        json_response(workflow)
      end

      def index
        relation = if params[:template_id]
                     template = Template.find(params.require(:template_id))
                     template.workflows
                   elsif for_resource_object?
                     WorkflowFindService.new.find(resource_object_params)
                   else
                     Workflow.all
                   end

        collection(policy_scope(relation))
      end

      def destroy
        workflow = Workflow.find(params.require(:id))
        authorize workflow

        workflow.destroy!
        head :no_content
      rescue ActiveRecord::InvalidForeignKey => e
        json_response({ :message => e.message }, :forbidden)
      rescue ActiveRecord::RecordNotDestroyed
        raise unless workflow.errors[:base].include?(Workflow::MSG_PROTECTED_RECORD)

        json_response({ :message => Workflow::MSG_PROTECTED_RECORD }, :forbidden)
      end

      def link
        WorkflowLinkService.new(params.require(:id)).link(params_for_create.to_unsafe_h)

        head :no_content
      end

      def unlink
        WorkflowUnlinkService.new(params[:id]).unlink(resource_object_params)

        head :no_content
      end

      def update
        workflow = Workflow.find(params.require(:id))
        authorize workflow

        # TODO: need to change params_for_update when using insights-api-commons
        WorkflowUpdateService.new(workflow.id).update(params_for_create)

        json_response(workflow)
      end

      private

      def collection(base_query)
        resp = Insights::API::Common::PaginatedResponse.new(
          :base_query => filtered(scoped(base_query)),
          :request    => request,
          :limit      => params[:limit],
          :offset     => params[:offset]
        ).response

        json_response(resp)
      end

      def resource_object_params
        @resource_object_params ||= params.slice(:object_type, :object_id, :app_name).to_unsafe_h
      end

      def for_resource_object?
        raise Exceptions::UserError, "Invalid resource object params: #{resource_object_params}" unless resource_object_params.length.zero? || resource_object_params.length == 3

        !!(resource_object_params[:app_name] && resource_object_params[:object_id] && resource_object_params[:object_type])
      end
    end
  end
end
