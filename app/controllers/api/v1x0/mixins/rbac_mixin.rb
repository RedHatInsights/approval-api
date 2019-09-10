module Api
  module V1x0
    module Mixins
      module RBACMixin
        include RBAC::Permissions

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

        # Klass here is allowed for Request, Stage and Action.
        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          permission_check(verb, klass)

          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass} with id: #{id}" unless resource_instance_accessible?(klass.table_name, id)
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless RBAC::Access.enabled?

          raise Exceptions::NotAuthorizedError, "#{verb.titleize} access not authorized for #{klass}" unless resource_accessible?(klass.table_name, verb)
        end

        # permission level check
        def resource_accessible?(resource, verb)
          admin? || owner_acls(resource, verb).any? || RBAC::Access.new(resource, verb).process.acl.any?
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
          @assigned_roles ||= RBAC::Roles.new.roles
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
          id_list(resource, approver_request_ids)
        end

        # resource ids owner owns
        def owner_id_list(resource)
          id_list(resource, owner_request_ids)
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
          Request.by_owner.pluck(:id).sort
        end

        # Request ids approver can process
        def approver_request_ids
          Request.where(:workflow_id => workflow_ids).pluck(:id).sort
        end

        # Id list for resource #{resource}
        def id_list(resource, request_ids)
          case resource
          when "requests"
            request_ids
          when "stages"
            stage_ids(request_ids)
          when "actions"
            action_ids(request_ids)
          else
            raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}"
          end
        end

        # Stage ids associated with request ids #{request_ids}
        def stage_ids(request_ids)
          Stage.where(:request_id => request_ids).pluck(:id).sort
        end

        # Action ids associated with request ids #{request_ids}
        def action_ids(request_ids)
          Action.where(:stage_id => stage_ids(request_ids)).pluck(:id).sort
        end

        # The accessible workflow ids for approver
        def workflow_ids
          approval_access = RBAC::Access.new('workflows', 'approve').process
          approval_access.send(:generate_ids)

          Rails.logger.info("Accessible workflows: #{approval_access.id_list}")

          approval_access.id_list
        end

        # The access list regular requesters have
        def requester_acls
          RBAC::ACLS.new.create(nil, OWNER_PERMISSIONS)
        end
      end
    end
  end
end
