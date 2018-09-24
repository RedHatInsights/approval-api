class WorkflowController < ApplicationController
  before_action :set_template
  before_action :set_template_workflow, only: [:show, :update, :destroy]

  # GET /templates/:template_id/workflows
  def list_by_template
    json_response(@template.workflows)
  end

  # GET /templates/:template_id/workflows/:id
  def show
    json_response(@workflow)
  end

  # GET /workflows
  def list
    @workflows = Workflow.all
    json_response(@workflows)
  end

  # POST /templates/:template_id/workflows
  def create
    @template.workflows.create!(workflow_params)
    json_response(@workflow, :created)
  end

  # PUT /templates/:template_id/workflows/:id
  def update
    @workflow.update(workflow_params)
    head :no_content
  end

  # DELETE /templates/:template_id/workflows/:id
  def destroy
    @workflow.destroy
    head :no_content
  end

  private

  def workflow_params
    params.permit(:name)
  end

  def set_template
    @template = Template.find(params[:template_id])
  end

  def set_template_workflow
    @workflow = @template.workflows.find_by!(id: params[:id]) if @template
  end
end
