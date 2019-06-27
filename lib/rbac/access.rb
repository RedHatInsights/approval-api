module RBAC
  class Access
    attr_reader :acls
    attr_reader :approver_acls
    attr_reader :owner, :approver, :admin

    def initialize(resource, verb)
      @resource      = resource
      @verb          = verb
      @regexp        = Regexp.new(":(#{@resource}|\\*):(#{@verb}|\\*)")
      @app_name      = ENV["APP_NAME"] || "approval"
      @admin         = false
      @approver      = false
      @owner         = false
      @acls          = []
      @approver_acls = []
    end

    def process
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        Rails.logger.info("Fetch access list for #{@app_name}")
        @acls = RBAC::Service.paginate(api, :get_principal_access, {}, @app_name).select do |item|
          Rails.logger.info("Found ACL: #{item}")
          @regexp.match(item.permission)
        end

        @acls.any? do |item|
          item.resource_definitions.any? do |rd|
            @admin = true if rd.attribute_filter.key == 'id' &&
                             rd.attribute_filter.operation == 'equal' &&
                             rd.attribute_filter.value == '*'
            @owner = true if rd.attribute_filter.key == 'owner' &&
                             rd.attribute_filter.operation == 'equal' &&
                             rd.attribute_filter.value == '{{username}}'
          end
        end
        @owner = false if @admin

        unless @admin
          approver_regexp = Regexp.new(":(workflows|\\*):(approve|\\*)")
          @approver_acls = RBAC::Service.paginate(api, :get_principal_access, {}, @app_name).select do |item|
            approver_regexp.match(item.permission)
          end
          @approver = true if approver_acls.any?
        end
      end
      Rails.logger.info("Role: admin[#{@admin}], approver[#{@approver}], owner[#{@owner}]; accessible?:[#{accessible?}]")

      self
    end

    def id_list
      case @resource
      when "requests"
        request_ids
      when "stages"
        stage_ids
      when "actions"
        action_ids
      else
        raise Exceptions::NotAuthorizedError, "Not Authorized for #{@resource}"
      end
    end

    def accessible?
      @acls.any?
    end

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end

    def owner?
      @owner
    end

    def admin?
      @admin
    end

    def approver?
      @approver
    end

    private

    def request_ids
      Request.where(:workflow_id => workflow_ids).pluck(:id)
    end

    def stage_ids
      # Only list out processed/processing stages
      Stage.where(:request_id => request_ids).where.not(:state => Stage::PENDING_STATE).pluck(:id)
    end

    def action_ids
      Action.where(:stage_id => stage_ids).pluck(:id)
    end

    def workflow_ids
      ids = SortedSet.new
      @approver_acls.each do |acl|
        acl.resource_definitions.any? do |rd|
          next unless rd.attribute_filter.key == 'id'
          next unless rd.attribute_filter.operation == 'equal'

          ids << rd.attribute_filter.value.to_i
        end
      end
      @workflow_ids = ids.to_a
      Rails.logger.info("Workflows can be accessed: #{@workflow_ids}")
      @workflow_ids
    end
  end
end
