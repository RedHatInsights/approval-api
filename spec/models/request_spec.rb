RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }
  it { should have_many(:stages) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }

  around do |example|
    ManageIQ::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      example.call
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
