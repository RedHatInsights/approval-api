RSpec.describe Api::V1x0::RootController, :type => :request do
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }
  let(:api_version) { version }

  context "v1.0" do
    it "#openapi.json" do
      get "#{api_version}/openapi.json", :headers => request_header

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "redirects properly" do
      get "#{api_version.split('.').first}/openapi.json", :headers => request_header

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("#{api_version}/openapi.json")
    end
  end
end
