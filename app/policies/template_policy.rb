class TemplatePolicy < ApplicationPolicy
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

  # define for graphql
  def query?
    permission_check('read', record)
  end
end
