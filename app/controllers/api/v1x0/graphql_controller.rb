require "insights/api/common/graphql"

module Api
  module V1x0
    class GraphqlController < ApplicationController
      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema(request, overlay)
        variables = ::Insights::API::Common::GraphQL.ensure_hash(params[:variables])
        result = graphql_api_schema.execute(
          params[:query],
          :variables => variables,
          :context   => {
            :policy_scope_method => method(:policy_method)
          }
        )
        render :json => result
      end

      def overlay
        {
          "^.*$" => {
            "base_query" => lambda do |model_class, graphql_args, ctx|
              ps_method = ctx[:policy_scope_method]
              ps_method.call(model_class, graphql_args)
            end
          }
        }
      end

      def policy_method(model_class, graphql_args)
        UserContext.current_user_context.graphql_params = graphql_args
        policy_scope(model_class)
      end
    end
  end
end
