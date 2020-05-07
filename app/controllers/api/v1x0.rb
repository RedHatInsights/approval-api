module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.2"]
      end
    end
    class ActionsController     < Api::V1x2::ActionsController; end
    class GraphqlController     < Api::V1x2::GraphqlController; end
    class RequestsController    < Api::V1x2::RequestsController; end
    class StageactionController < Api::V1x2::StageactionController; end
    class TemplatesController   < Api::V1x2::TemplatesController; end
    class WorkflowsController   < Api::V1x2::WorkflowsController; end
  end
end
