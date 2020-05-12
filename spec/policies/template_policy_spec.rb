describe TemplatePolicy do
  include_context "approval_rbac_objects"

  let(:template) { create(:template) }
  subject { described_class.new(user, template) }

  describe '#show? and #user_capabilities' do
    it 'returns true for admin role' do
      admin_access
      expect(subject.show?).to be_truthy
      expect(subject.user_capabilities).to eq({'show' => true})
    end

    it 'returns false for approver role' do
      approver_access
      expect(subject.show?).to be_falsey
      expect(subject.user_capabilities).to eq({'show' => false})
    end

    it 'returns false for user role' do
      user_access
      expect(subject.show?).to be_falsey
      expect(subject.user_capabilities).to eq({'show' => false})
    end
  end
end
