module Mixins
  module RBACMixin
    include Insights::API::Common::RBAC
    include ApprovalPermissions

    APPROVER_VISIBLE_STATES = [ApprovalStates::NOTIFIED_STATE, ApprovalStates::COMPLETED_STATE].freeze
    APP_NAME = ENV['APP_NAME'] || 'approval'.freeze

    def resource_check(verb, id = @record.id, klass = @record.class)
      permission_check(verb, klass) ? resource_instance_accessible?(klass, verb, id) : false
    end

    def permission_check(verb, resource = @record)
      return true unless Insights::API::Common::RBAC::Access.enabled?

      klass = resource_class(resource)
      @user.access.accessible?(klass.table_name, verb, APP_NAME)
    end

    # instance level check
    def resource_instance_accessible?(resource, verb, resource_id)
      return true if admin?(resource, verb)

      approver?(resource, verb) && approvable?(resource.table_name, resource_id) || requester?(resource, verb) && owned?(resource.table_name, resource_id)
    end

    def admin?(resource = @record, verb = 'read')
      klass = resource_class(resource)
      @user.access.admin_scope?(klass.table_name, verb, APP_NAME)
    end

    def approver?(resource = @record, verb = 'read')
      klass = resource_class(resource)
      @user.access.group_scope?(klass.table_name, verb, APP_NAME)
    end

    def requester?(resource = @record, verb = 'read')
      klass = resource_class(resource)
      @user.access.user_scope?(klass.table_name, verb, APP_NAME)
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

    def resource_class(resource)
      if resource.class == Class
        resource
      elsif resource.respond_to?(:model)
        resource.model
      elsif resource.instance_of?(resource.class)
        resource.class
      else
        raise ArgumentError, "Unknown resource type: #{resource} in permission check"
      end
    end
  end
end
