module Api
  module V1x0
    module Mixins
      module RBACMixin
        # create action only needs class level permission check
        def create_access_check
          permission_check('create')
        end

        # Currently destroy and update actions are only for Workflow, only admin has such permissions.
        def destroy_access_check
          permission_check('destroy')
        end

        def index_access_check
          permission_check('read')
        end

        def update_access_check
          permission_check('update')
        end

        # In addition to class level permission, read action also needs to check its owner/approvers scope.
        def read_access_check
          resource_check('read')
        end

        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          access = permission_check(verb, klass)

          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" unless access.resource_instance_accessible?(klass.table_name, id)
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless RBAC::Access.enabled?

          access = RBAC::ApprovalAccess.new(klass.table_name, verb).process
          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" unless access.resource_accessible?

          access
        end
      end
    end
  end
end
