module UserOperationsMixin
  extend ActiveSupport::Concern

  def add_request
    req = RequestCreateService.new(params[:workflow_id]).create(request_params)
    json_response(req, :created)
  end

  def fetch_request_by_id
    req = Request.find(params[:id])
    json_response(req)
  end

  def fetch_request_stages
    req = Request.find(params[:request_id])

    json_response(req.stages)
  end

  private

  def request_params
    params.permit(:name, :decision, :state, :requester, :content)
  end

end
