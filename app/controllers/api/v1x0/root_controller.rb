module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Rails.root.join('public', 'approval', 'v1.0', 'openapi.json').read
      end
    end
  end
end
