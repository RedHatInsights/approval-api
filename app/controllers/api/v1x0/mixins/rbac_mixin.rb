module Api
  module V1x0
    module Mixins
      module RBACMixin
        include RBAC::Permissions

        ADMIN_ROLE = 'Approval Administrator'.freeze
        APPROVER_ROLE = 'Approval Approver'.freeze

        APPROVER_ROLE_PREFIX = 'approval-group-'.freeze

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
          return unless RBAC::Access.enabled?

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
          stage_ids = approver_stage_ids
          raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}" if stage_ids.empty?

          Rails.logger.info("Final accessible stage ids: #{stage_ids}")

          case resource
          when "requests"
            stage_ids.map { |stage_id| Stage.find(stage_id).request_id }
          when "stages"
            stage_ids
          when "actions"
            Action.where(:stage_id => stage_ids).pluck(:id).sort
          else
            raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}"
          end
        end

        # resource ids owner owns
        def owner_id_list(resource)
          case resource
          when "requests"
            owner_request_ids
          when "stages"
            owner_stage_ids(owner_request_ids)
          when "actions"
            Action.where(:stage_id => owner_stage_ids(owner_request_ids)).pluck(:id).sort
          else
            raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}"
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
          Request.by_owner.pluck(:id).sort
        end

        # Request ids approver can process
        def approver_request_ids
          Request.where(:workflow_id => workflow_ids).pluck(:id).sort
        end

        # lookup table between stage ids and group refs
        def stages_groups
          request_ids = approver_request_ids
          Rails.logger.info("Approvable request ids: #{request_ids}")

          Stage.where(:request_id => request_ids).each_with_object({}) do |stage, ids|
            ids[stage.id] = stage.group_ref
          end
        end

        def approver_stage_ids
          group_ids = assigned_group_ids
          Rails.logger.info("Groups from assigned roles: #{group_ids}")

          # stage ids after filtering with user groups
          stage_ids = stages_groups.select { |_stage_id, group_id| group_ids.include?(group_id) }.keys
          Rails.logger.info("Approvable stage ids after filtering with assigned groups: #{stage_ids}")

          # another filtering based on stage index inside request
          stage_ids.select do |stage_id|
            stage = Stage.find(stage_id)
            if stage.index_of_request > stage.request.active_stage_number
              Rails.logger.info("Stage #{stage.id} is filtered out because it is still in next stages.")
            end

            stage.index_of_request <= stage.request.active_stage_number
          end
        end

        def assigned_group_ids
          assigned_roles.map { |name, _id| name.split(APPROVER_ROLE_PREFIX)[1] }.compact
        end

        # Stage ids associated with request ids #{request_ids}
        def owner_stage_ids(request_ids)
          Stage.where(:request_id => request_ids).pluck(:id).sort
        end

        # The accessible workflow ids for approver
        def workflow_ids
          approval_access = RBAC::Access.new('workflows', 'approve').process
          approval_access.send(:generate_ids)

          Rails.logger.info("Approvable workflows: #{approval_access.id_list}")

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
