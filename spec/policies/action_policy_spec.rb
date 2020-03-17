describe ActionPolicy do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:user) { instance_double(UserContext, :params => params, :controller_name => 'Action') }
  let(:subject) { described_class.new(user, Action) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, hash_including(:limit), any_args).and_return(acls)
    allow(subject).to receive(:validate_create_action).and_return(true)
  end

  describe 'with admin role' do
    let(:acls) { admin_acls }
    let(:params) { { :id => actions.first.id } }

    #before { allow(subject).to receive(:validate_create_action).and_return(true) }

    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    it '#show?' do
      expect(subject.show?).to be_truthy
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end

  describe 'with approver role' do
    let(:params) { { :id => actions.first.id } }
    let(:acls) { approver_acls }

    before do
      allow(subject).to receive(:approver_id_list).and_return([actions.first.id, actions.last.id])
    end

    # also be a regular requester
    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    context 'when id is in the approver_id_list' do
      let(:params) { { :id => actions.first.id } }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the approver_id_list' do
      let(:params) { { :id => actions.second.id } }

      it '#show? with the id not in the list' do
        expect { subject.show? }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end

  describe 'with requester role' do
    let(:acls) { requester_acls }
    let(:params) { { :id => actions.first.id } }

    before do
      allow(subject).to receive(:owner_id_list).and_return([actions.first.id, actions.last.id])
    end

    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    it '#show?' do
      expect { subject.show? }.to raise_error(Exceptions::NotAuthorizedError)
    end

    it '#query?' do
      expect { subject.show? }.to raise_error(Exceptions::NotAuthorizedError)
    end
  end
end
