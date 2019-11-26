module Api
  module V1
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.0"]
      end
    end
  end
end
