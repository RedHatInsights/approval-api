class ContextService
  attr_reader :context

  def initialize(context)
    @context = context
  end

  def with_context(&block)
    switch_context(context, &block)
  end

  def as_org_admin(&block)
    switch_context(org_admin_context, &block)
  end

  private

  def org_admin_context
    decoded = Base64.urlsafe_decode64(context["headers"]["x-rh-identity"])
    decoded.sub!(/"is_org_admin":false/, '"is_org_admin":true')
    context.deep_dup.tap do |new_context|
      new_context["headers"]["x-rh-identity"] = Base64.urlsafe_encode64(decoded)
    end
  end

  def switch_context(new_context)
    Insights::API::Common::Request.with_request(new_context.transform_keys(&:to_sym)) do |current|
      ActsAsTenant.with_tenant(Tenant.find_by(:external_tenant => current.tenant)) { yield }
    end
  end
end
