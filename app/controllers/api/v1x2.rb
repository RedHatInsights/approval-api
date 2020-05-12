module Api
  module V1x2
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.2"]
      end
    end
  end
end
