module Api
  module V0x1
    module Mixins
      module IndexMixin
        def scoped(relation)
          if relation.model.respond_to?(:taggable?) && relation.model.taggable?
            ref_schema = {relation.model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query)
          resp = ManageIQ::API::Common::PaginatedResponse.new(
            :base_query => scoped(base_query),
            :request    => request,
            :limit      => params.permit(:limit)[:limit],
            :offset     => params.permit(:offset)[:offset]
          ).response

          json_response(resp)
        end
      end
    end
  end
end
