RSpec.describe ContextService do
  let(:request) { FactoryBot.create(:request, :with_context) }
  subject { described_class.new(request.context) }

  describe '#with_context' do
    context 'request with context' do
      it 'sets the http request header and current tenant' do
        subject.with_context do
          expect(Insights::API::Common::Request.current.to_h).to eq(request.context.transform_keys(&:to_sym))
          expect(ActsAsTenant.current_tenant).to eq(request.tenant)
        end
      end
    end

    context 'request without context' do
      let(:request) { FactoryBot.create(:request, :with_tenant) }

      it 'raises an error' do
        expect { subject.with_context }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#as_org_admin' do
    it 'sets the http request header with is_org_admin == true' do
      subject.as_org_admin do
        expect(Insights::API::Common::Request.current.user.org_admin?).to be_truthy
      end
    end
  end
end
