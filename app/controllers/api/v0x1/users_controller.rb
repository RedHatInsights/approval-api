module Api
  module V0x1
    class UsersController < ApplicationController
      include Mixins::IndexMixin

      def create
        user = User.create!(user_params)
        json_response(user, :created)
      end

      def show
        user = User.find(params.require(:id))
        json_response(user)
      end

      def index
        if params[:group_id]
          group = Group.find(params.require(:group_id))
          collection(group.users)
        else
          users = User.all
          collection(users)
        end
      end

      def destroy
        User.find(params.require(:id)).destroy
        head :no_content
      end

      def update
        User.find(params.require(:id)).update(user_params)
        head :no_content
      end

      private

      def user_params
        params.permit(:email, :first_name, :last_name, :limit, :offset, :group_ids => [])
      end
    end
  end
end
