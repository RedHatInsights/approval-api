RSpec.describe Api::V1x0::StageactionController do
  describe '#set_order' do
    before { subject.instance_variable_set(:@request,  create(:request, :random_access_key => 'rand1')) }

    it 'sets order date and time in correct format' do
      order = subject.send(:set_order)

      expect(order[:order_date]).to match(/\d+ [a-zA-Z]+ \d+/)
      expect(order[:order_time]).to match(/\d+:\d+ UTC/)
    end
  end

  describe '#decrypt_request' do
    let!(:request) {create(:request, :random_access_key => 'randomaccess01')}
    let(:encrypt_str) { "v2:{kyJF88jQeU5rUb5vno8amwty5ZdFEacj+EagyGWjk4U=}" }

    it 'decrypts random_access_key and requester' do
      request1, requester = subject.send(:decrypt_request, encrypt_str)
      expect(request1).to eq(request)
      expect(requester).to eq('Joe Doe')
    end
  end
end
