module Api
  module V0x1
    class StagesController < ApplicationController
      def show
        stage = Stage.find(params.require(:id))
        json_response(stage)
      end

      def index
        req = Request.find(params.require(:request_id))
        json_response(req.stages)
      end
    end
  end
end
