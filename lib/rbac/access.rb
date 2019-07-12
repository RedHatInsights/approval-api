module RBAC
  class Access
    include RBAC::Permissions
    attr_reader :acls, :approver_acls, :owner_acls

    def initialize(resource, verb)
      @resource      = resource
      @verb          = verb
      @app_name      = ENV["APP_NAME"] || "approval"
      @admin         = false
      @approver      = false
      @owner         = false
      @acls          = []
      @approver_acls = []
      @owner_acls    = []
    end

    def process
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        Rails.logger.info("Fetch access list for #{@app_name}")
        full_acls = RBAC::Service.paginate(api, :get_principal_access, {}, @app_name)

        regexp = Regexp.new(":(#{@resource}|\\*):(#{@verb}|\\*)")
        approver_regexp = Regexp.new(":(workflows|\\*):(approve|\\*)")

        full_acls.each do |item|
          Rails.logger.debug("Found ACL: #{item}")
          @acls << item if regexp.match(item.permission)

          unless @admin
            item.resource_definitions.any? do |rd|
              @admin = true if rd.attribute_filter.key == 'id' &&
                               rd.attribute_filter.operation == 'equal' &&
                               rd.attribute_filter.value == '*'
            end
          end

          @approver_acls << item if approver_regexp.match(item.permission)
        end

        @approver = true if approver_acls.any?

        @owner_acls = requester_acls.select do |item|
          regexp.match(item.permission)
        end

        @owner = true if @owner_acls.any?
      end

      Rails.logger.info("Role: admin[#{@admin}], approver[#{@approver}], owner[#{@owner}]")

      self
    end

    # resource ids approver can approve
    def approver_id_list
      id_list(approver_requests)
    end

    # resource ids owner owns
    def owner_id_list
      id_list(owner_requests)
    end

    # request ids that approver can approve
    def approver_requests
      @approver_requests ||= approver_request_ids
    end

    # request ids that owner owns
    def owner_requests
      @owner_requests ||= owner_request_ids
    end

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end

    # permission level check
    def accessible?
      @acls.any? || @owner_acls.any?
    end

    # approver but cannot approve the resource
    def not_approvable?(resource_id)
      resource_ids = approver_id_list
      @approver && resource_ids && resource_ids.exclude?(resource_id)
    end

    # owner but does not own the resource
    def not_owned?(resource_id)
      resource_ids = owner_id_list
      @owner && resource_ids && resource_ids.exclude?(resource_id)
    end

    def admin?
      @admin
    end

    def approver?
      @approver
    end

    def owner?
      @owner
    end

    private

    def owner_request_ids
      Request.by_owner.pluck(:id)
    end

    def approver_request_ids
      Request.where(:workflow_id => workflow_ids).pluck(:id)
    end

    def id_list(request_ids)
      case @resource
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

    def stage_ids(request_ids)
      Stage.where(:request_id => request_ids).pluck(:id)
    end

    def action_ids(request_ids)
      Action.where(:stage_id => stage_ids(request_ids)).pluck(:id)
    end

    def workflow_ids
      @workflow_ids ||= begin
        ids = SortedSet.new
        @approver_acls.each do |acl|
          acl.resource_definitions.any? do |rd|
            next unless rd.attribute_filter.key == 'id'
            next unless rd.attribute_filter.operation == 'equal'

            ids << rd.attribute_filter.value.to_i
          end
        end

        Rails.logger.info("Accessible workflows: #{ids}")

        ids.to_a
      end
    end

    def requester_acls
      RBAC::ACLS.new.create(nil, OWNER_PERMISSIONS)
    end
  end
end
