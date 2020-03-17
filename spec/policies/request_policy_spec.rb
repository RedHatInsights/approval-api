describe RequestPolicy do
  include_context "approval_rbac_objects"

  let(:requests) { create_list(:request, 3) }
  let(:user) { instance_double(UserContext, :params => params, :controller_name => 'Request') }
  let(:subject) { described_class.new(user, Request) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).with(api_instance, :get_principal_access, hash_including(:limit), any_args).and_return(acls)
    #allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe 'with admin role' do
    let(:acls) { admin_acls }
    let(:params) { { :id => requests.first.id } }

    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    it '#show?' do
      expect(subject.show?).to be_truthy
    end

    it '#index?' do
      expect(subject.index?).to be_truthy
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end

  describe 'with approver role' do
    let(:params) { { :id => requests.first.id } }
    let(:acls) { approver_acls }

    before do
      allow(subject).to receive(:approver_id_list).and_return([requests.first.id, requests.last.id])
    end

    # also be a regular requester
    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    context 'when id is in the approver_id_list' do
      let(:params) { { :id => requests.first.id } }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the approver_id_list' do
      let(:params) { { :id => requests.second.id } }

      it '#show? with the id not in the list' do
        expect { subject.show? }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    context 'when parent request id is in the approver_id_list' do
      let(:params) { { :id => requests.second.id, :request_id => requests.first.id } }

      it '#index?' do
        expect(subject.index?).to be_truthy
      end
    end

    context 'when parent request id is not in the approver_id_list' do
      let(:params) { { :id => requests.first.id, :request_id => requests.second.id } }

      it '#index?' do
        expect { subject.index? }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end

  describe 'with requester role' do
    let(:acls) { requester_acls }
    let(:params) { { :id => requests.first.id } }

    before do
      allow(subject).to receive(:owner_id_list).and_return([requests.first.id, requests.last.id])
    end

    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    context 'when id is in the owner_id_list' do
      let(:params) { { :id => requests.first.id } }

      it '#show? with the id in the list' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when id is not in the owner_id_list' do
      let(:params) { { :id => requests.second.id } }

      it '#show? with the id no5 in the list' do
        expect { subject.show? }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    context 'when parent request id is in the owner_id_list' do
      let(:params) { { :id => requests.second.id, :request_id => requests.first.id } }

      it '#index?' do
        expect(subject.index?).to be_truthy
      end
    end

    context 'when parent request id is not in the owner_id_list' do
      let(:params) { { :id => requests.first.id, :request_id => requests.second.id } }

      it '#index?' do
        expect { subject.index? }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end
end
