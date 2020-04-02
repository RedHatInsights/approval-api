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
  end
end
