module Api
  module V1x0
    module Mixins
      module RBACMixin
        def create_access_check
          permission_check('create')
        end

        def read_access_check
          resource_check('read')
        end

        def update_access_check
          resource_check('update')
        end

        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          access_obj = permission_check(verb, klass)

          if access_obj.approver?
            ids = access_obj.id_list
            raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" if ids.any? && ids.exclude?(id.to_i)
          end

          klass.where(:id => id).by_owner if access_obj.owner?
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless RBAC::Access.enabled?
          access_obj = RBAC::Access.new(klass.table_name, verb).process
          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
          access_obj
        end
      end
    end
  end
end
