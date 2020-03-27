describe RequestPolicy do
  include_context "approval_rbac_objects"

  let(:requests) { create_list(:request, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access) }

  describe 'with admin role' do
    let(:accessible_flag) { true }
    before { allow(access).to receive(:admin_scope?).and_return(true) }

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when record is an instance' do
      let(:subject) { described_class.new(user, requests.first) }

      it '#show?' do
        expect(subject.show?).to be_truthy
      end
    end
  end

  describe 'with approver role' do
    before do
      allow(subject).to receive(:approver_id_list).and_return([requests.first.id, requests.last.id])
      allow(access).to receive(:admin_scope?).and_return(false)
      allow(access).to receive(:group_scope?).and_return(true)
      allow(access).to receive(:user_scope?).and_return(false)
    end

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }
      let(:accessible_flag) { false }

      it '#create?' do
        expect(subject.create?).to be_falsey
      end
    end

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }
      let(:accessible_flag) { true }

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when id is in the approver_id_list' do
      let(:subject) { described_class.new(user, requests.first) }
      let(:accessible_flag) { true }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the approver_id_list' do
      let(:subject) { described_class.new(user, requests.second) }
      let(:accessible_flag) { true }

      it '#show? with the id not in the list' do
        expect(subject.show?).to be_falsey
      end
    end
  end

  describe 'with requester role' do
    let(:accessible_flag) { true }

    before do
      allow(subject).to receive(:owner_id_list).and_return([requests.first.id, requests.last.id])
      allow(access).to receive(:admin_scope?).and_return(false)
      allow(access).to receive(:group_scope?).and_return(false)
      allow(access).to receive(:user_scope?).and_return(true)
    end

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when id is in the owner_id_list' do
      let(:subject) { described_class.new(user, requests.first) }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the owner_id_list' do
      let(:subject) { described_class.new(user, requests.second) }

      it '#show? with the id no5 in the list' do
        expect(subject.show?).to be_falsey
      end
    end
  end
end
