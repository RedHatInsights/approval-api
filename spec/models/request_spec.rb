RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }
  it { should have_many(:stages) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }

  describe '#as_json' do
    subject { FactoryBot.create(:request, :stages => stages) }

    context 'all stages are pending or notified' do
      let(:stages) do
        [FactoryBot.create(:stage, :id => 1, :state => Stage::NOTIFIED_STATE),
         FactoryBot.create(:stage, :id => 2, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :id => 3, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the last stage' do
        expect(subject.as_json).to include(:active_stage => 1, :total_stages => 3)
        expect(subject.current_stage.id).to eq(1)
      end
    end

    context 'all stages are completed' do
      let(:stages) do
        [FactoryBot.create(:stage, :state => Stage::FINISHED_STATE),
         FactoryBot.create(:stage, :state => Stage::SKIPPED_STATE),
         FactoryBot.create(:stage, :state => Stage::SKIPPED_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include(:active_stage => 3, :total_stages => 3)
        expect(subject.current_stage).to be_nil
      end
    end

    context 'some stage is active' do
      let(:stages) do
        [FactoryBot.create(:stage, :id => 1, :state => Stage::FINISHED_STATE),
         FactoryBot.create(:stage, :id => 2, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :id => 3, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include(:active_stage => 2, :total_stages => 3)
        expect(subject.current_stage.id).to eq(2)
      end
    end
  end
end
