RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }
  it { should have_many(:stages) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }

  describe '#switch_context' do
    context 'with context' do
      it 'sets the http request header and current tenant' do
        request = FactoryBot.create(:request, :with_context)
        request.switch_context do
          expect(ManageIQ::API::Common::Request.current.to_h).to eq(request.context.transform_keys(&:to_sym))
          expect(ActsAsTenant.current_tenant).to eq(request.tenant)
        end
      end
    end

    context 'without context' do
      it 'raises an error' do
        request = FactoryBot.create(:request, :with_tenant)
        expect { request.switch_context }.to raise_error(ArgumentError)
      end
    end
  end
end
