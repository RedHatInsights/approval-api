class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    permission_check('read')
  end
end
