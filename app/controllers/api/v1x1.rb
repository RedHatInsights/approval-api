module Api
  module V1x1
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.1"]
      end
    end
    class ActionsController     < Api::V1x0::ActionsController; end
    class GraphqlController     < Api::V1x0::GraphqlController; end
    class RequestsController    < Api::V1x0::RequestsController; end
    class StageactionController < Api::V1x0::StageactionController; end
    class TemplatesController   < Api::V1x0::TemplatesController; end
    class WorkflowsController   < Api::V1x0::WorkflowsController; end
  end
end
