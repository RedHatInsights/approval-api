describe Kie::Service do
  let(:kie_ex) { KieClient::ApiError.new("kie_error") }
  let(:options) { {} }

  describe '.call' do
    it 'raises a KieClient::ApiError' do
      expect do
        described_class.call(KieClient::ProcessInstancesBPMApi, options) do |_api|
          raise kie_ex
        end
      end.to raise_exception(Exceptions::KieError)
    end
  end
end
