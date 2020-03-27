describe TemplatePolicy::Scope do
  include_context "approval_rbac_objects"

  let(:templates) { create_list(:template, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access) }
  let(:subject) { described_class.new(user, Template) }

  describe '#resolve' do
    context 'when admin role' do
      let(:accessible_flag) { true }
      before { allow(access).to receive(:admin_scope?).and_return(true) }

      it 'returns templates' do
        expect(subject.resolve).to match_array(templates)
      end
    end

    context 'when approver role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    context 'when requester role' do
      let(:accessible_flag) { false }

      it 'returns templates' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
