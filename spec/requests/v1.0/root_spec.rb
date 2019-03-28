RSpec.describe "root", :type => :request do
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:api_version) { version }

  context "v1.0" do
    it "#openapi.json" do
      get "#{api_version}/openapi.json", :headers => request_header

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end
end
