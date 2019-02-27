class User
  attr_accessor :username
  attr_accessor :email
  attr_accessor :first_name
  attr_accessor :last_name
  attr_accessor :is_org_admin
  attr_writer   :users

  def org_admin?
    !!is_org_admin
  end

  def self.find_by_username(username)
    user = nil
    RBACService.call(RBACApiClient::PrincipalApi) do |api|
      user = from_raw(api.get_principal(username))
    end
    user
  end

  def self.all
    users = []
    RBACService.call(RBACApiClient::PrincipalApi) do |api|
      RBACService.paginate(api, :list_principals, {}).each do |item|
        users << from_raw(item)
      end
    end
    users
  end

  def groups
    # TODO: wait for API available
    []
  end

  private_class_method def self.from_raw(raw_user)
    new.tap do |user|
      user.username = raw_user.username
      user.email = raw_user.email
      user.first_name = raw_user.first_name
      user.last_name = raw_user.last_name
      user.is_org_admin = raw_user.is_org_admin
      # TODO: user.groups
    end
  end
end
