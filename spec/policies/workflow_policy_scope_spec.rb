describe WorkflowPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:workflows) { create_list(:workflow, 3) }
  let(:user) { instance_double(UserContext) }
  let(:subject) { described_class.new(user, Workflow) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe '#resolve' do
    context 'when admin role' do
      let(:acls) { admin_acls }

      it 'returns workflows' do
        expect(subject.resolve).to match_array(workflows)
      end
    end

    context 'when approver role' do
      let(:acls) { approver_acls }

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError, "Read access not authorized for Workflow")
      end
    end

    context 'when requester role' do
      let(:acls) { requester_acls }

      it 'returns workflows' do
        expect(subject.resolve).to match_array(workflows)
      end
    end
  end
end
