module Api
  module V1
    module Mixins
      module RBACMixin
        include ApprovalPermissions

        ADMIN_ROLE = 'Approval Administrator'.freeze
        APPROVER_ROLE = 'Approval Approver'.freeze

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

        # Klass here is allowed for Request, Stage and Action.
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
          admin? || owner_acls(resource, verb).any? || Insights::API::Common::RBAC::Access.new(resource, verb).process.acl.any?
        end

        # instance level check
        def resource_instance_accessible?(resource, resource_id)
          admin? || approvable?(resource, resource_id) || owned?(resource, resource_id)
        end

        def admin?
          assigned_roles.include?(ADMIN_ROLE)
        end

        def approver?
          assigned_roles.include?(APPROVER_ROLE)
        end

        def assigned_roles
          @assigned_roles ||= Insights::API::Common::RBAC::Roles.new.roles
        end

        # check if approver can process the #{resource} with #{id}
        def approvable?(resource, id)
          approver? && approver_id_list(resource)&.include?(id.to_i)
        end

        # check if regular requester own the #{resource} with #{id}
        def owned?(resource, id)
          owner_id_list(resource)&.include?(id.to_i)
        end

        # resource ids approver can approve
        def approver_id_list(resource)
          visible_request_ids = visible_request_ids_for_approver
          Rails.logger.info("Final accessible request ids: #{visible_request_ids}")

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

        # Owner access list for the #{resource} and action #{verb}
        def owner_acls(resource, verb)
          regexp = Regexp.new(":(#{resource}|\\*):(#{verb}|\\*)")
          requester_acls.select do |item|
            regexp.match(item.permission)
          end
        end

        # Request ids owned by requester
        def owner_request_ids
          Request.by_owner.where(:parent_id => nil).pluck(:id).sort
        end

        # All child request ids for approver to process
        def all_request_ids_for_approver
          Request.where(:workflow_id => workflow_ids).pluck(:id).sort
        end

        def visible_request_ids_for_approver
          request_ids = all_request_ids_for_approver
          Rails.logger.info("All approvable request ids: #{request_ids}")

          group_refs = assigned_group_refs
          Rails.logger.info("Groups from assigned roles: #{group_refs}")

          visible_states = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE]
          Request.where(:id => request_ids, :group_ref => group_refs, :state => visible_states).pluck(:id)
        end

        def assigned_group_refs
          assigned_roles.map { |name, _id| name.split(AccessProcessService::APPROVER_ROLE_PREFIX)[1] }.compact
        end

        # The accessible workflow ids for approver
        def workflow_ids
          approval_access = Insights::API::Common::RBAC::Access.new('workflows', 'approve').process

          Rails.logger.info("Approvable workflows: #{approval_access.id_list}")

          approval_access.id_list
        end

        # The access list regular requesters have
        def requester_acls
          Insights::API::Common::RBAC::ACL.new.create(nil, OWNER_PERMISSIONS)
        end
      end
    end
  end
end
