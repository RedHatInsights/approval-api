class WorkflowPolicy < ApplicationPolicy
  include Mixins::RBACMixin

  class Scope
    include Mixins::RBACMixin

    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope.all if permission_check('read')
    end
  end

  def create?
    permission_check('create')
  end

  def show?
    permission_check('read')
  end

  def update?
    permission_check('update')
  end

  def destroy?
    permission_check('destroy')
  end

  def query?
    permission_check('read', record)
  end
end
