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

  describe '#as_json' do
    subject { FactoryBot.create(:request, :stages => stages) }

    context 'all stages are pending or notified' do
      let(:stages) do
        [FactoryBot.create(:stage, :state => Stage::NOTIFIED_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include('active_stage' => 1, 'total_stages' => 3)
      end
    end

    context 'all stages are completed' do
      let(:stages) do
        [FactoryBot.create(:stage, :state => Stage::FINISHED_STATE),
         FactoryBot.create(:stage, :state => Stage::SKIPPED_STATE),
         FactoryBot.create(:stage, :state => Stage::SKIPPED_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include('active_stage' => 3, 'total_stages' => 3)
      end
    end

    context 'some stage is active' do
      let(:stages) do
        [FactoryBot.create(:stage, :state => Stage::FINISHED_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include('active_stage' => 2, 'total_stages' => 3)
      end
    end
  end
end
