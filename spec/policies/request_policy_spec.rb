describe RequestPolicy do
  include_context "approval_rbac_objects"

  let(:requests) { create_list(:request, 3) }
  let(:user) { instance_double(UserContext) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, hash_including(:limit), any_args).and_return(acls)
  end

  describe 'with admin role' do
    let(:acls) { admin_acls }

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
    let(:acls) { approver_acls }

    before do
      allow(subject).to receive(:approver_id_list).and_return([requests.first.id, requests.last.id])
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

    context 'when id is in the approver_id_list' do
      let(:subject) { described_class.new(user, requests.first) }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the approver_id_list' do
      let(:subject) { described_class.new(user, requests.second) }

      it '#show? with the id not in the list' do
        expect(subject.show?).to be_falsey
      end
    end
  end

  describe 'with requester role' do
    let(:acls) { requester_acls }

    before do
      allow(subject).to receive(:owner_id_list).and_return([requests.first.id, requests.last.id])
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
