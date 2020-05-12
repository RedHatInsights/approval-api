class ApplicationPolicy
  include Mixins::RBACMixin

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def user_capabilities
    capabilities = {}

    (self.class.instance_methods(false).select { |method| method.to_s.end_with?("?") }).each do |method|
      capabilities[method.to_s.delete_suffix('?')] = send(method)
    end

    capabilities
  end

  class Scope
    include Mixins::RBACMixin

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all unless user.rbac_enabled?

      graphql_query_by_id? ? graphql_id_query : resolve_scope
    end

    def resolve_scope
      raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}" unless permission_check('read', scope)

      scope.all
    end

    private

    def graphql_id_query
      id = user.graphql_params.id

      item = scope.find(id)
      raise Exceptions::NotAuthorizedError, "Read access not authorized for request #{item.id}" unless resource_check('read', item)

      scope
    end

    def graphql_query_by_id?
      !!user.graphql_params&.id
    end
  end
end
