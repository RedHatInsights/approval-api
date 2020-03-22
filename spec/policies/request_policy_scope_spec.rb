describe RequestPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:requests) { create_list(:request, 3) }
  let(:user) { instance_double(UserContext) }
  let(:subject) { described_class.new(user, Request.all) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe '#resolve' do
    context 'when admin role' do
      let(:acls) { admin_acls }

      it 'returns requests' do
        expect(subject.resolve).to match_array(requests)
      end
    end

    context 'when approver role' do
      let(:acls) { approver_acls }

      before do
        allow(subject).to receive(:approver_id_list).and_return([requests.first.id, requests.last.id])
      end

      it 'returns requests' do
        expect(subject.resolve.sort).to eq(Request.where(:id => [requests.first.id, requests.last.id]).sort)
      end
    end

    context 'when requester role' do
      let(:acls) { requester_acls }

      before do
        allow(subject).to receive(:owner_id_list).and_return([requests.second.id])
      end

      it 'returns requests' do
        expect(subject.resolve).to eq(Request.where(:id => [requests.second.id]))
      end
    end
  end
end
