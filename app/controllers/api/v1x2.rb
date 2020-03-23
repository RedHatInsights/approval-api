module Api
  module V1x2
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.2"]
      end
    end
    class ActionsController     < Api::V1x0::ActionsController; end
    class GraphqlController     < Api::V1x0::GraphqlController; end
    class RequestsController    < Api::V1x0::RequestsController; end
    class StageactionController < Api::V1x0::StageactionController; end
    class TemplatesController   < Api::V1x0::TemplatesController; end
  end
end
