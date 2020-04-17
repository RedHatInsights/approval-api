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

    (self.class.instance_methods(false).select {|method| method.to_s.end_with?("?")}).each do |method|
      capabilities[method.to_s.delete_suffix('?')] = self.send(method)
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
      scope.all
    end

    def graphql_id_query
      id = user.graphql_params.id

      item = scope.find(id)
      raise Exceptions::NotAuthorizedError, "Read access not authorized for request #{item.id}" unless resource_check('read', item)

      scope.where(:id => id)
    end

    def graphql_filter_query
      scope.where(user.graphql_params.filter)
    end

    def graphql_collection_query
      graphql_query_by_filter? ? graphql_filter_query : scope.all
    end

    def graphql_query_by_id?
      graphql_query? && user.graphql_params.id.present?
    end

    def graphql_query_by_filter?
      graphql_query? && user.graphql_params.filter.present?
    end

    def graphql_query?
      !!user.graphql_params
    end
  end
end
