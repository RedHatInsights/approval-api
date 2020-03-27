describe ActionPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:params) { { :request_id => request.id } }
  let(:user) { instance_double(UserContext, :params => params, :access => access) }
  let(:subject) { described_class.new(user, Action.all) }

  describe '#resolve' do
    context 'when admin role' do
      let(:accessible_flag) { true }
      before { allow(access).to receive(:admin_scope?).and_return(true) }

      it 'returns actions' do
        expect(subject.resolve).to match_array(actions)
      end
    end

    context 'when approver role' do
      let(:accessible_flag) { true }

      before do
        allow(subject).to receive(:approver_id_list).and_return([actions.first.id, actions.last.id, request.id])
        allow(access).to receive(:admin_scope?).and_return(false)
        allow(access).to receive(:group_scope?).and_return(true)
      end

      it 'returns actions' do
        expect(subject.resolve.sort).to eq(Action.where(:id => [actions.first.id, actions.last.id]).sort)
      end
    end

    context 'when requester role' do
      let(:accessible_flag) { false }

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
