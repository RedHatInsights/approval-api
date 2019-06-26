module Api
  module V1x0
    module Mixins
      module IndexMixin
        def scoped(relation)
          relation = rbac_scope(relation) if RBAC::Access.enabled?
          if relation.model.respond_to?(:taggable?) && relation.model.taggable?
            ref_schema = {relation.model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query)
          resp = ManageIQ::API::Common::PaginatedResponse.new(
            :base_query => filtered(scoped(base_query)),
            :request    => request,
            :limit      => params.permit(:limit)[:limit],
            :offset     => params.permit(:offset)[:offset]
          ).response

          json_response(resp)
        end

        def rbac_scope(relation)
          access_obj = RBAC::Access.new(relation.model.table_name, 'read').process
          raise Exceptions::NotAuthorizedError, "Not Authorized for #{relation.model}" unless access_obj.accessible?

          return relation if access_obj.admin?

          owner_relation = relation.by_owner if access_obj.owner?
          approver_relation = relation.where(:id => access_obj.id_list) if access_obj.approver?

          Rails.logger.info("Owner scope: #{owner_relation.pluck(:id)}") if owner_relation
          Rails.logger.info("approver scope: #{approver_relation.pluck(:id)}") if approver_relation

          return owner_relation.or(approver_relation) if owner_relation && approver_relation

          approver_relation ? approver_relation : owner_relation
        end

        def filtered(base_query)
          ManageIQ::API::Common::Filter.new(base_query, params[:filter], api_doc_definition).apply
        end

        private

        def api_doc_definition
          @api_doc_definition ||= Api::Docs[api_version].definitions[model_name]
        end

        def api_version
          @api_version ||= name.split("::")[1].downcase.delete("v").sub("x", ".")
        end

        def model_name
          # Because approval uses the In/Out objects - we need to handle that appropriately.
          @model_name ||= (controller_name.singularize + "Out").classify
        end

        def name
          self.class.to_s
        end
      end
    end
  end
end
