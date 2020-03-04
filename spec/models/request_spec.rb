RSpec.describe Request, type: :model do
  it { should belong_to(:request_context) }
  it { should belong_to(:workflow) }
  it { should belong_to(:parent) }
  it { should have_many(:actions) }
  it { should have_many(:children) }
  it { should have_many(:random_access_keys) }

  it { should validate_presence_of(:name) }

  describe '#number_of_children and #number_of_finished_children' do
    subject { FactoryBot.create(:request, :children => children) }

    context 'no children' do
      let(:children) { [] }

      it 'has 0 children and 0 finished children' do
        subject.invalidate_number_of_children
        subject.invalidate_number_of_finished_children
        expect(subject.number_of_children).to eq(0)
        expect(subject.number_of_finished_children).to eq(0)
      end
    end

    context 'all children are finished' do
      let(:children) do
        [
          FactoryBot.create(:request, :state => Request::COMPLETED_STATE),
          FactoryBot.create(:request, :state => Request::CANCELED_STATE),
          FactoryBot.create(:request, :state => Request::SKIPPED_STATE)
        ]
      end

      it 'has 3 children and 3 finished children' do
        subject.invalidate_number_of_children
        subject.invalidate_number_of_finished_children
        expect(subject.number_of_children).to eq(3)
        expect(subject.number_of_finished_children).to eq(3)
      end
    end

    context 'some children are finished' do
      let(:children) do
        [
          FactoryBot.create(:request, :state => Request::COMPLETED_STATE),
          FactoryBot.create(:request, :state => Request::PENDING_STATE),
          FactoryBot.create(:request, :state => Request::PENDING_STATE)
        ]
      end

      it 'has 3 children and 1 finished children' do
        subject.invalidate_number_of_children
        subject.invalidate_number_of_finished_children
        expect(subject.number_of_children).to eq(3)
        expect(subject.number_of_finished_children).to eq(1)
      end
    end
  end

  describe '#create_child' do
    subject { FactoryBot.create(:request) }
    it 'creates a child' do
      child = subject.create_child
      expect(child).to have_attributes(
        :name               => subject.name,
        :description        => subject.description,
        :request_context_id => subject.request_context_id,
        :owner              => subject.owner,
        :requester_name     => subject.requester_name,
        :state              => Request::PENDING_STATE,
        :decision           => Request::UNDECIDED_STATUS,

        :number_of_children          => 0,
        :number_of_finished_children => 0
      )

      expect(subject.number_of_children).to eq(1)
      expect(subject.number_of_finished_children).to be_zero
    end
  end

  describe '#parent? and #child?' do
    subject { FactoryBot.create(:request, :children => children) }

    before { subject.invalidate_number_of_children }

    context 'no child' do
      let(:children) { [] }

      it 'is a single node' do
        expect(subject.root?).to be_truthy
        expect(subject.leaf?).to be_truthy
        expect(subject.parent?).to be_falsey
        expect(subject.child?).to be_falsey
      end
    end

    context 'with children' do
      let(:child) { FactoryBot.create(:request) }
      let(:children) { [child] }

      it 'detects parent and child' do
        expect(subject.root?).to be_truthy
        expect(subject.leaf?).to be_falsey
        expect(subject.parent?).to be_truthy
        expect(subject.child?).to be_falsey

        expect(child.root?).to be_falsey
        expect(child.leaf?).to be_truthy
        expect(child.parent?).to be_falsey
        expect(child.child?).to be_truthy
      end
    end
  end
end
