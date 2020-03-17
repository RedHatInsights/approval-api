describe ActionPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:params) { { :request_id => request.id } }
  let(:user) { instance_double(UserContext, :params => params, :controller_name => 'Action') }
  let(:subject) { described_class.new(user, Action.all) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe '#resolve' do
    context 'when admin role' do
      let(:acls) { admin_acls }

      it 'returns actions' do
        expect(subject.resolve).to match_array(actions)
      end
    end

    context 'when approver role' do
      let(:acls) { approver_acls }

      before do
        allow(subject).to receive(:approver_id_list).and_return([actions.first.id, actions.last.id, request.id])
      end

      it 'returns actions' do
        expect(subject.resolve.sort).to eq(Action.where(:id => [actions.first.id, actions.last.id]).sort)
      end
    end

    context 'when requester role' do
      let(:acls) { requester_acls }

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
