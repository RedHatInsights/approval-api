module Api
  module V1x0
    class StagesController < ApplicationController
      include Mixins::IndexMixin

      def show
        stage = Stage.find(params.require(:id))
        json_response(stage)
      end

      def index
        req = Request.find(params.require(:request_id))
        collection(req.stages)
      end
    end
  end
end
