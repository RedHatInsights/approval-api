describe TemplatePolicy do
  include_context "approval_rbac_objects"

  let(:templates) { create_list(:template, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access) }
  let(:subject) { described_class.new(user, Template) }

  describe '#query?' do
    context 'when admin role' do
      let(:accessible_flag) { true }
      before { allow(access).to receive(:admin_scope?).and_return(true) }

      it 'returns templates' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'when approver role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect(subject.query?).to be_falsey
      end
    end

    context 'when requester role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect(subject.query?).to be_falsey
      end
    end
  end
end
