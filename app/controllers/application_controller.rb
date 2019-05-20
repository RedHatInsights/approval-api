class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      if current.required_auth?
        raise ManageIQ::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

        begin
          ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
        rescue Exceptions::NoTenantError
          json_response({ :message => 'Unauthorized' }, :unauthorized)
        end
      else
        ActsAsTenant.without_tenant { yield }
      end
    end
  end

  def current_tenant(current_user)
    tenant = Tenant.find_or_create_by(:external_tenant => current_user.tenant) if current_user.tenant.present?
    return tenant if tenant
    raise  Exceptions::NoTenantError
  end

  def check_entitled(entitlement)
    required_entitlements = %i[hybrid_cloud?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end
end
