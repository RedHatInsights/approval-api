require "insights/api/common/graphql"

module Api
  module V1x0
    class GraphqlController < ApplicationController
      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema(request, overlay)
        variables = ::Insights::API::Common::GraphQL.ensure_hash(params[:variables])
        result =
          begin
            Thread.current[:graphql_controller] = self
            graphql_api_schema.execute(
              params[:query],
              :variables => variables
            )
          ensure
            Thread.current[:graphql_controller] = nil
          end
        render :json => result
      end

      def overlay
        {
          "^.*$" => {
            "base_query" => lambda do |model_class, graphql_args, _ctx|
              UserContext.current_user_context.graphql_params = graphql_args
              Thread.current[:graphql_controller].policy_scope(model_class)
            end
          }
        }
      end
    end
  end
end
