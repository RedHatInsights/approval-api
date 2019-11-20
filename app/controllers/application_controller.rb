class ApplicationController < ActionController::API
  include Response
  include Insights::API::Common::ApplicationControllerMixins::ExceptionHandling
  include Insights::API::Common::ApplicationControllerMixins::ApiDoc
  include Insights::API::Common::ApplicationControllerMixins::Common
  include Insights::API::Common::ApplicationControllerMixins::RequestBodyValidation
  include Insights::API::Common::ApplicationControllerMixins::RequestPath
  include Insights::API::Common::ApplicationControllerMixins::Parameters

  around_action :with_current_request

  private

  def with_current_request
    Insights::API::Common::Request.with_request(request) do |current|
      raise Insights::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

      begin
        ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
      rescue Exceptions::NoTenantError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      end
    end
  end

  def current_tenant(current_user)
    tenant = Tenant.find_or_create_by(:external_tenant => current_user.tenant) if current_user.tenant.present?
    return tenant if tenant
    raise  Exceptions::NoTenantError
  end

  def check_entitled(entitlement)
    required_entitlements = %i[ansible?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end
end
