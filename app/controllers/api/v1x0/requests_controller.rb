module Api
  module V1x0
    class RequestsController < ApplicationController
      include Mixins::IndexMixin

      def create
        authorize Request

        req = RequestCreateService.new.create(params_for_create)
        json_response(req, :created)
      end

      def show
        req = Request.find(params.require(:id))
        authorize req

        request.path.end_with?("/content") ? json_response(req.content) : json_response(req)
      end

      def index
        collection(policy_scope(Request))
      end
   end
  end
end
