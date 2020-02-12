class Group
  attr_accessor :name
  attr_accessor :description
  attr_accessor :uuid
  attr_writer   :users
  attr_writer   :roles

  def self.find(uuid)
    group = nil
    Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      group = from_raw(api.get_group(uuid))
    end
    group
  end

  def self.all(username = nil)
    groups = []
    Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
      Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :username => username).each do |item|
        groups << from_raw(item)
      end
    end
    groups
  end

  def users
    @users ||= Group.find(uuid).users
  end

  def roles
    @roles ||= Group.find(uuid).roles
  end

  def has_role?(role_name)
    roles.any? { |role| role.name == role_name }
  end

  private_class_method def self.from_raw(raw_group)
    new.tap do |group|
      group.uuid = raw_group.uuid
      group.name = raw_group.name
      group.description = raw_group.description
      group.users = raw_group.try(:principals)
      group.roles = raw_group.try(:roles)
    end
  end
end
