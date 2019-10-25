RSpec.describe Request, type: :model do
  it { should belong_to(:workflow) }
  it { should have_many(:stages) }
  it { should have_many(:children) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:content) }

  describe '#as_json' do
    subject { FactoryBot.create(:request, :stages => stages) }

    context 'all stages are pending or notified' do
      let(:stages) do
        [FactoryBot.create(:stage, :state => Stage::NOTIFIED_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include(:active_stage => 1, :total_stages => 3)
        expect(subject.current_stage.id).to eq(stages[0].id)
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
        [FactoryBot.create(:stage, :state => Stage::FINISHED_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE),
         FactoryBot.create(:stage, :state => Stage::PENDING_STATE)]
      end

      it 'has active_stage pointing to the first stage' do
        expect(subject.as_json).to include(:active_stage => 2, :total_stages => 3)
        expect(subject.current_stage.id).to eq(stages[1].id)
      end
    end
  end

  describe '#number_of_children and #number_of_finished_children' do
    subject { FactoryBot.create(:request, :children => children) }

    context 'no children' do
      let(:children) { [] }

      it 'has 0 children and 0 finished children' do
        expect(subject.number_of_children).to eq(0)
        expect(subject.number_of_finished_children).to eq(0)
      end
    end

    context 'all children are finished' do
      let(:children) do
        [
          FactoryBot.create(:request, :state => Request::FINISHED_STATE),
          FactoryBot.create(:request, :state => Request::CANCELED_STATE),
          FactoryBot.create(:request, :state => Request::SKIPPED_STATE)
        ]
      end

      it 'has 3 children and 3 finished children' do
        expect(subject.number_of_children).to eq(3)
        expect(subject.number_of_finished_children).to eq(3)
      end
    end

    context 'some children are finished' do
      let(:children) do
        [
          FactoryBot.create(:request, :state => Request::FINISHED_STATE),
          FactoryBot.create(:request, :state => Request::PENDING_STATE),
          FactoryBot.create(:request, :state => Request::PENDING_STATE)
        ]
      end

      it 'has 3 children and 1 finished children' do
        expect(subject.number_of_children).to eq(3)
        expect(subject.number_of_finished_children).to eq(1)
      end
    end
  end
end
