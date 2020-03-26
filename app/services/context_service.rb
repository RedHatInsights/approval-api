class ContextService
  attr_reader :context

  def initialize(context)
    @context = context
  end

  def with_context(&block)
    switch_context(context, false, &block)
  end

  def as_org_admin(&block)
    if ENV['RBAC_PSK']
      begin
        switch_context(context, true, &block)
      ensure
        Thread.current[:rbac_extra_headers] = nil
      end
    else
      switch_context(org_admin_context, false, &block)
    end
  end

  private

  def org_admin_context
    decoded = Base64.urlsafe_decode64(context["headers"]["x-rh-identity"])
    decoded.sub!(/"is_org_admin":false/, '"is_org_admin":true')
    context.deep_dup.tap do |new_context|
      new_context["headers"]["x-rh-identity"] = Base64.urlsafe_encode64(decoded)
    end
  end

  def service_to_service_headers
    {
      'x-rh-rbac-psk'       => ENV['RBAC_PSK'],
      'x-rh-rbac-account'   => ActsAsTenant.current_tenant.external_tenant,
      'x-rh-rbac-client-id' => 'approval',
      'x-rh-identity'       => nil
    }
  end

  def switch_context(new_context, extra_headers)
    Insights::API::Common::Request.with_request(new_context.transform_keys(&:to_sym)) do |current|
      ActsAsTenant.with_tenant(Tenant.find_by(:external_tenant => current.tenant)) do
        Thread.current[:rbac_extra_headers] = service_to_service_headers if extra_headers
        yield
     end
    end
  end
end
