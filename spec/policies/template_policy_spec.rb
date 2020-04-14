describe TemplatePolicy do
  include_context "approval_rbac_objects"

  let(:template) { create(:template) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :rbac_enabled? => true, :access => access) }

  subject { described_class.new(user, template) }

  describe '#show?' do
    context 'when admin role' do
      let(:accessible_flag) { true }

      it 'returns templates' do
        expect(subject.show?).to be_truthy
      end
    end

    context 'when approver role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect(subject.show?).to be_falsey
      end
    end

    context 'when requester role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect(subject.show?).to be_falsey
      end
    end
  end
end
