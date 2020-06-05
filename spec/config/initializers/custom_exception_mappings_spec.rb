RSpec.describe ActionDispatch::ExceptionWrapper do
  let(:status_symbols) { Rack::Utils::SYMBOL_TO_STATUS_CODE.keys }

  it 'maps an error class to a valid http status symbol' do
    described_class.rescue_responses.each do |key, value|
      expect(key.constantize).to be_truthy
      expect(status_symbols).to include(value)
    end
  end
end
