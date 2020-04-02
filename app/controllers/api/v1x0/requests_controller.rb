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
        relation = if params[:request_id]
                     Request.find(params.require(:request_id)).children
                   else
                     Request
                   end

        collection(policy_scope(relation))
      end
   end
  end
end
