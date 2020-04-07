describe ActionPolicy do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:group_uuids) { ['group_uid'] }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :group_uuids => group_uuids) }

  before do
    allow(subject).to receive(:validate_create_action).and_return(true)
  end

  describe 'with admin role' do
    before { allow(access).to receive(:scopes).and_return(['admin']) }

    context 'when action resource is model class' do
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
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
    before do
      allow(access).to receive(:scopes).and_return(['group'])
    end

    context 'when action resource is model class' do
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end
    end

    context 'when action resource is instance' do
      let(:subject) { described_class.new(user, actions.first) }

      context 'when approver is assigned to approve the request' do
        before { request.update(:group_ref => group_uuids.first, :state => 'notified') }

        it 'is allowed to show the action instance' do
          expect(subject.show?).to be_truthy
        end
      end

      context 'when approver is not assigned to approve the request' do
        it 'is not allowed to show the action instance' do
          expect(subject.show?).to be_falsey
        end
      end
    end
  end

  describe 'with requester role' do
    before { allow(access).to receive(:scopes).and_return(['user']) }

    context 'when action resource is model class' do
      let(:subject) { described_class.new(user, Action) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end
    end

    context 'when action resource is instance' do
      around do |example|
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          example.call
        end
      end

      let(:subject) { described_class.new(user, actions.first) }

      context 'when requester is owner of the request' do
        it 'is allowed to show the action instance' do
          expect(subject.show?).to be_truthy
        end
      end

      context 'when requester is not owner of the request' do
        before { request.update(:owner => 'ugly name') }

        it 'is not allowed to show the action instance' do
          expect(subject.show?).to be_falsey
        end
      end
    end
  end
end
