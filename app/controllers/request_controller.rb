class RequestController < ApplicationController
  before_action :set_workflow
  before_action :set_workflow_request, only: [:show, :update, :destroy]

  # GET /workflows/:workflow_id/requests
  def list_by_workflow
    json_response(@workflow.requests)
  end

  # GET /workflows/:workflow_id/requests/:id
  def show
    json_response(@request)
  end

  # GET /requests
  def list
    json_response(Request.all)
  end

  # POST /workflows/:workflow_id/requests
  def create
    @workflow.requests.create!(request_params)
    json_response(@request, :created)
  end

  # PUT /workflows/:workflow_id/requests/:id
  def update
    @request.update(request_params)
    head :no_content
  end

  # DELETE /workflows/:workflow_id/requests/:id
  def destroy
    @request.destroy
    head :no_content
  end

  private

  def request_params
    params.permit(:name, :status, :state, :uuid, :content)
  end

  def set_workflow
    @workflow = Workflow.find(params[:workflow_id])
  end

  def set_workflow_request
    @request = @workflow.requests.find_by!(id: params[:id]) if @workflow
  end
end
