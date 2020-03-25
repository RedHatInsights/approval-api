module Api
  module V1x0
    module Mixins
      module RBACMixin
        include ApprovalPermissions

        ADMIN_ROLE = 'Approval Administrator'.freeze
        APPROVER_ROLE = 'Approval Approver'.freeze
        APPROVER_VISIBLE_STATES = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE].freeze

        # create action only needs class level permission check
        def create_access_check
          permission_check('create')
        end

        # Currently destroy and update actions are only for Workflow, only admin has such permissions.
        def destroy_access_check
          permission_check('destroy')
        end

        def index_scope(relation)
          return relation unless Insights::API::Common::RBAC::Access.enabled?

          permission_check('read')
          rbac_scope(relation)
        end

        def update_access_check
          permission_check('update')
        end

        # In addition to class level permission, read action also needs to check its owner/approvers scope.
        def read_access_check
          resource_check('read')
        end

        # Klass here is allowed for Request and Action.
        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          return unless Insights::API::Common::RBAC::Access.enabled?

          permission_check(verb, klass)

          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass} with id: #{id}" unless resource_instance_accessible?(klass.table_name, id)
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless Insights::API::Common::RBAC::Access.enabled?

          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" unless resource_accessible?(klass.table_name, verb)
        end

        # permission level check
        def resource_accessible?(resource, verb)
          return true if admin?

          permitted?(OWNER_PERMISSIONS, resource, verb) || approver? && permitted?(APPROVER_PERMISSIONS, resource, verb)
        end

        # instance level check
        def resource_instance_accessible?(resource, resource_id)
          return true if admin?

          approver? ? approvable?(resource, resource_id) : owned?(resource, resource_id)
        end

        def admin?
          assigned_roles.include?(ADMIN_ROLE)
        end

        def approver?
          assigned_roles.include?(APPROVER_ROLE)
        end

        def requester?
          !admin? && !approver?
        end

        def assigned_roles
          @assigned_roles ||= Insights::API::Common::RBAC::Roles.new('approval').roles
        end

        # check if approver can process the #{resource} with #{id}
        def approvable?(resource, id)
          approver_id_list(resource)&.include?(id.to_i)
        end

        # check if regular requester own the #{resource} with #{id}
        def owned?(resource, id)
          owner_id_list(resource)&.include?(id.to_i)
        end

        # resource ids approver can access
        def approver_id_list(resource)
          visible_request_ids = visible_request_ids_for_approver
          Rails.logger.debug { "Final accessible request ids: #{visible_request_ids}" }

          case resource
          when "requests"
            visible_request_ids
          when "actions"
            Action.where(:request_id => visible_request_ids).pluck(:id).sort
          else
            raise ArgumentError, "Unknown resource type: #{resource}"
          end
        end

        # resource ids owner owns
        def owner_id_list(resource)
          case resource
          when "requests"
            owner_request_ids
          when "actions"
            Action.where(:request_id => owner_request_ids).pluck(:id).sort
          else
            raise ArgumentError, "Unknown resource type: #{resource}"
          end
        end

        def permitted?(permissions, resource, verb)
          regexp = Regexp.new(":(#{resource}|\\*):(#{verb}|\\*)")
          permissions.any? do |item|
            regexp.match?(item)
          end
        end

        # Request ids owned by requester
        def owner_request_ids
          Request.by_owner.pluck(:id).sort
        end

        # All child request ids for approver to process
        def visible_request_ids_for_approver
          Request.where(:group_ref => assigned_group_refs, :state => APPROVER_VISIBLE_STATES).pluck(:id)
        end

        def assigned_group_refs
          Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
            Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
          end
        end
      end
    end
  end
end
