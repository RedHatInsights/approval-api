class UserContext
  attr_reader :request, :params

  def initialize(request, params = nil)
    @request = request
    @params = params
  end

  def access 
    @access ||= Insights::API::Common::RBAC::Access.new.process
  end

  def group_uuids
    @group_uuids ||= Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
    end
  end

  def rbac_enabled?
    @rbac_enabled ||= Insights::API::Common::RBAC::Access.enabled?
  end
end
