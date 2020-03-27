describe ActionPolicy do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access) }

  before do
    allow(subject).to receive(:validate_create_action).and_return(true)
  end

  describe 'with admin role' do
    let(:accessible_flag) { true }
    before { allow(access).to receive(:admin_scope?).and_return(true) }

    context 'when action resource is model class' do
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when action resource is instance' do
      let(:subject) { described_class.new(user, actions.first) }

      it '#show?' do
        expect(subject.show?).to be_truthy
      end
    end
  end

  describe 'with approver role' do
    let(:accessible_flag) { true }
    before do
      allow(subject).to receive(:approver_id_list).and_return([actions.first.id, actions.last.id])
      allow(access).to receive(:admin_scope?).and_return(false)
      allow(access).to receive(:group_scope?).and_return(true)
      allow(access).to receive(:user_scope?).and_return(false)
    end

    context 'when action resource is model class' do
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when action resource is instance' do
      context 'when id is in the approver_id_list' do
        let(:subject) { described_class.new(user, actions.first) }

        it '#show?' do
          expect(subject.show?).to be_truthy
        end
      end

      context 'when id is not in the approver_id_list' do
        let(:subject) { described_class.new(user, actions.second) }

        it '#show? with the id not in the list' do
          expect(subject.show?).to be_falsey
        end
      end
    end
  end

  describe 'with requester role' do
    before do
      allow(subject).to receive(:owner_id_list).and_return([actions.first.id, actions.last.id])
      allow(access).to receive(:admin_scope?).and_return(false)
      allow(access).to receive(:group_scope?).and_return(false)
      allow(access).to receive(:user_scope?).and_return(true)
    end

    context 'when action resource is model class' do
      let(:accessible_flag) { true }
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end
    end

    context 'when action resource is model class, permission_check is false' do
      let(:accessible_flag) { false }
      let(:subject) { described_class.new(user, Action) }

      it '#query?' do
        expect(subject.query?).to be_falsey
      end
    end

    context 'when action resource is instance' do
      let(:subject) { described_class.new(user, actions.first) }
      let(:accessible_flag) { false }

      it '#show?' do
        expect(subject.show?).to be_falsey
      end
    end
  end
end
