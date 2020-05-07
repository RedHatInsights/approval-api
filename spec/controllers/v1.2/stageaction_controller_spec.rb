RSpec.describe Api::V1x2::StageactionController do
  describe '#set_order' do
    before { subject.instance_variable_set(:@request,  create(:request)) }

    it 'sets order date and time in correct format' do
      order = subject.send(:set_order)

      expect(order[:order_date]).to match(/\d+ [a-zA-Z]+ \d+/)
      expect(order[:order_time]).to match(/\d+:\d+ UTC/)
    end
  end
end
