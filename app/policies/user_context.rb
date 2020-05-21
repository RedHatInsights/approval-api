class UserContext
  attr_reader :request, :params
  MAX_GROUPS_LIMIT = 500

  def initialize(request, params = nil)
    @request = request
    @params = params
  end

  def access
    @access ||= Insights::API::Common::RBAC::Access.new.process
  end

  def group_uuids
    opts = {:scope => 'principal', :limit => MAX_GROUPS_LIMIT}
    @group_uuids ||= Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, opts).collect(&:uuid)
    end
  end

  def graphql_params=(val)
    @graphql_params = val
  end

  def graphql_params
    @graphql_params
  end

  def rbac_enabled?
    @rbac_enabled ||= Insights::API::Common::RBAC::Access.enabled?
  end

  def self.current_user_context
    Thread.current[:user_context]
  end

  def self.with_user_context(user_context)
    saved_user_context   = Thread.current[:user_context]
    self.current_user_context = user_context
    yield current_user_context
  ensure
    Thread.current[:user_context] = saved_user_context
  end

  def self.current_user_context=(user_context)
    Thread.current[:user_context] = user_context
  end
end
