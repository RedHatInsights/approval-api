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
          resource = relation.model.table_name
          access_obj = RBAC::Access.new(resource, 'read').process
          raise Exceptions::NotAuthorizedError, "Not Authorized to list #{relation.model}" unless access_obj.accessible?

          # return UserError for wrong path
          if resource == "requests" &&
             !(access_obj.approver? && request.path.end_with?("/approver_requests")) &&
             !(access_obj.owner? && request.path.end_with?("/owner_requests")) &&
             !(access_obj.admin? && request.path.end_with?("/requests"))
            raise Exceptions::NotAuthorizedError, "Current role cannot access #{request.path}"
          end

          approver_relation = relation.where(:id => access_obj.approver_id_list)
          Rails.logger.info("approver scope: #{approver_relation.pluck(:id)}")

          owner_relation = relation.where(:id => access_obj.owner_id_list)
          Rails.logger.info("Owner scope: #{owner_relation.pluck(:id)}")

          return relation if access_obj.admin?

          # double roles for requests
          if resource == "requests" && approver_relation.any? && owner_relation.any?
            return request.path.end_with?("approver_requests") ? approver_relation : owner_relation
          end

          # For other resources
          return approver_relation if approver_relation.any?

          owner_relation
        end

        def filtered(base_query)
          ManageIQ::API::Common::Filter.new(base_query, params[:filter], api_doc_definition).apply
        end

        def rbac_read_access(relation)
          access_obj = RBAC::Access.new(relation.model.table_name, 'read').process
          raise Exceptions::NotAuthorizedError, "Not Authorized to list #{relation.model.table_name}" unless access_obj.accessible?

          access_obj
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
