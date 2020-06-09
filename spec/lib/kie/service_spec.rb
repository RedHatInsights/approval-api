describe Kie::Service do
  let(:kie_ex) { KieClient::ApiError.new(:message => "kie_error", :code => 1) }
  let(:kie_nil_ex) { KieClient::ApiError.new("kie_error") }
  let(:kie_zero_ex) { KieClient::ApiError.new(:messsage => "kie_error", :code => 0) }
  let(:options) { {} }

  describe '.call' do
    it 'raises a KieClient::ApiError' do
      expect do
        described_class.call(KieClient::ProcessInstancesBPMApi, options) do |_api|
          raise kie_ex
        end
      end.to raise_exception(Exceptions::KieError)

      expect do
        described_class.call(KieClient::ProcessInstancesBPMApi, options) do |_api|
          raise kie_nil_ex
        end
      end.to raise_exception(Exceptions::TimedOutError)

      expect do
        described_class.call(KieClient::ProcessInstancesBPMApi, options) do |_api|
          raise kie_zero_ex
        end
      end.to raise_exception(Exceptions::NetworkError)
    end
  end

  it "sets the authorization headers" do
    auth_headers = described_class.call(KieClient::ProcessInstancesBPMApi, options) do |api|
      api.api_client.default_headers["Authorization"]
    end

    expect(auth_headers).to eq(KieClient.configure.basic_auth_token)
  end
end
