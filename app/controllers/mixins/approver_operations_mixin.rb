module ApproverOperationsMixin
  extend ActiveSupport::Concern

  def add_action
    action = ActionCreateService.new(params.require(:stage_id)).create(action_params)
    json_response(action, :created)
  end

  def fetch_action_by_id
    action = Action.find(params.require(:id))

    json_response(action)
  end

  def fetch_actions
    actions = Action.all

   json_response(actions)
  end

  def fetch_stage_by_id
    stage = Stage.find(params.require(:id))

    json_response(stage)
  end

  private

  def action_params
    params.permit(:operation, :processed_by, :comments)
  end
end
