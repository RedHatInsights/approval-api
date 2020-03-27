describe WorkflowPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:workflows) { create_list(:workflow, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access) }
  let(:subject) { described_class.new(user, Workflow) }

  describe '#resolve' do
    context 'when admin role' do
      let(:accessible_flag) { true }
      before { allow(access).to receive(:admin_scope?).and_return(true) }

      it 'returns workflows' do
        expect(subject.resolve).to match_array(workflows)
      end
    end

    context 'when approver role' do
      let(:accessible_flag) { false }
      before do
        allow(access).to receive(:admin_scope?).and_return(false)
        allow(access).to receive(:group_scope?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError, "Read access not authorized for Workflow")
      end
    end

    context 'when requester role' do
      let(:accessible_flag) { true }
      before do
        allow(access).to receive(:admin_scope?).and_return(false)
        allow(access).to receive(:group_scope?).and_return(false)
      end

      it 'returns workflows' do
        expect(subject.resolve).to match_array(workflows)
      end
    end
  end
end
