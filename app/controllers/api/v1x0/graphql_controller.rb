module Api
  module V1x0
    class GraphqlController < Api::V1::GraphqlController
      def overlay
        {
          "^.*$" => {
             "base_query" => lambda do |model_class, _ctx|
               "::Api::V1x0::#{model_class.to_s.pluralize}Controller".constantize.new.send(:rbac_scope, model_class.all)
             end
          }
        }
      end
    end
  end
end
