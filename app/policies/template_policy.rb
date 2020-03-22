class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      permission_check('read', scope) ? scope.all : (raise Exceptions::NotAuthorizedError, "Read access not authorized for #{scope}")
    end
  end

  # define for graphql
  def query?
    permission_check('read')
  end
end
