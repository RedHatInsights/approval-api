describe RequestPolicy do
  include_context "approval_rbac_objects"

  let(:requests) { create_list(:request, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:group_uuids) { ['group-uuid'] }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :group_uuids => group_uuids) }
  let(:headers) { {:headers => RequestSpecHelper::default_headers, :original_url=>'url'} }

  describe 'with admin role' do
    let(:accessible_flag) { true }
    before { allow(access).to receive(:scopes).and_return(['admin']) }

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }

      it '#create?' do
        expect(subject.create?).to be_truthy
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
      allow(access).to receive(:scopes).and_return(['group'])
    end

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }
      let(:accessible_flag) { false }

      it '#create?' do
        expect(subject.create?).to be_falsey
      end
    end

    context 'when record is a request approvable by approver' do
      let(:subject) { described_class.new(user, requests.first) }
      let(:accessible_flag) { true }
      before { requests.first.update(:group_ref => group_uuids.first, :state => 'completed') }

      it 'can be shown to the approver' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when record is a request not approvable by approver' do
      let(:subject) { described_class.new(user, requests.second) }
      let(:accessible_flag) { true }

      it 'cannot be shown to the approver' do
        expect(subject.show?).to be_falsey
      end
    end
  end

  describe 'with requester role' do
    let(:accessible_flag) { true }

    before do
      allow(access).to receive(:scopes).and_return(['user'])
    end

    context 'when record is model class' do
      let(:subject) { described_class.new(user, Request) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end
    end

    context 'when record is a request created by user' do
      let(:subject) { described_class.new(user, requests.first) }

      it 'can be shown to user' do
        Insights::API::Common::Request.with_request(headers) do
          requests.first.update(:owner => Insights::API::Common::Request.current.user.username)

          expect(subject.show?).to be_truthy
        end
      end
    end

    context 'when record is a request not created by user' do
      let(:subject) { described_class.new(user, requests.second) }

      it 'cannot be shown to user' do
        Insights::API::Common::Request.with_request(headers) do
          requests.second.update(:owner => 'ugly name')

          expect(subject.show?).to be_falsey
        end
      end
    end
  end
end
