module Api
  module V1x1
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.1"]
      end
    end
    class ActionsController     < Api::V1::ActionsController; end
    class GraphqlController     < Api::V1x0::GraphqlController; end
    class RequestsController    < Api::V1::RequestsController; end
    class StageactionController < Api::V1::StageactionController; end
    class TemplatesController   < Api::V1::TemplatesController; end
    class WorkflowsController   < Api::V1::WorkflowsController; end
  end
end
