module ApproverOperationsMixin
  extend ActiveSupport::Concern

  def add_action
    stage = Stage.find(params[:stage_id])
    action = stage.actions.create!(action_params)

    json_response(action, :created)
  end

  def fetch_action_by_id
    action = Action.find(params[:id])

    json_response(action)
  end

  def fetch_actions
    actions = Action.all

   json_response(actions)
  end

  def fetch_stage_by_id
    stage = Stage.find(params[:id])

    json_response(stage)
  end

  def remove_action
    Action.find(params[:id]).destroy

    head :no_content
  end

  def update_action
    Action.find(params[:id]).update(action_params)

    head :no_content
  end

  def update_stage
    StageUpdateService.new(params[:id]).update(stage_params)
    head :no_content
  end

end
