begin
  Api::V1x2::ActionsController
  Api::V1x2::GraphqlController
  Api::V1x2::RequestsController
  Api::V1x2::StageactionController
  Api::V1x2::TemplatesController
  Api::V1x2::WorkflowsController
rescue => exception
  Rails.logger.error("Failed to load rest controllers: #{exception.inspect}")
  exit(1)
end