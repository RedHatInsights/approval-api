# spec/support/request_spec_helper
module RequestSpecHelper
  module_function

  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end

  def version(ver = 'v1.0')
    "/api/#{ver}"
  end

  DEFAULT_USER = {
    "entitlements" => {
      "hybrid_cloud"     => {
        "is_entitled" => true
      },
      "insights"         => {
        "is_entitled" => true
      },
      "openshift"        => {
        "is_entitled" => true
      },
      "smart_management" => {
        "is_entitled" => true
      }
    },
    "identity" => {
      "account_number" => "0369233",
      "type"           => "User",
      "user"           => {
        "username"     => "jdoe",
        "email"        => "jdoe@acme.com",
        "first_name"   => "John",
        "last_name"    => "Doe",
        "is_active"    => true,
        "is_org_admin" => false,
        "is_internal"  => false,
        "locale"       => "en_US"
      },
      "internal"       => {
        "org_id"    => "3340851",
        "auth_type" => "basic-auth",
        "auth_time" => 6300
      }
    }
  }.freeze

  def encode(val)
    if val.kind_of?(Hash)
      hashed = val.stringify_keys
      Base64.strict_encode64(hashed.to_json)
    else
      raise StandardError, "Must be a Hash"
    end
  end

  def encoded_user_hash(hash = nil)
    encode(hash || DEFAULT_USER)
  end

  def default_user_hash
    Marshal.load(Marshal.dump(DEFAULT_USER))
  end

  def default_headers
    {'x-rh-identity' => encoded_user_hash, 'x-rh-insights-request-id' => 'gobbledygook'}
  end

  def default_request_hash
    {:headers => default_headers, :original_url => 'https://xyz.com/api/requests'}
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
