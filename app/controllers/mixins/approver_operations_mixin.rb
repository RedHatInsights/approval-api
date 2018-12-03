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

  def remove_action
    Action.find(params.require(:id)).destroy

    head :no_content
  end

  def update_action
    Action.find(params.require(:id)).update(action_params)

    head :no_content
  end

  def update_stage
    StageUpdateService.new(params.require(:id)).update(stage_params)
    head :no_content
  end

  private

  def action_params
    params.permit(:operation, :processed_by, :comments)
  end
end
