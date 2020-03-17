describe TemplatePolicy::Scope do
  include_context "approval_rbac_objects"

  let(:templates) { create_list(:template, 3) }
  let(:user) { instance_double(UserContext, :controller_name => 'Template') }
  let(:subject) { described_class.new(user, Template) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe '#resolve' do
    context 'when admin role' do
      let(:acls) { admin_acls }

      it 'returns templates' do
        expect(subject.resolve).to match_array(templates)
      end
    end

    context 'when approver role' do
      let(:acls) { approver_acls }

      it 'returns templates' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end

    context 'when requester role' do
      let(:acls) { requester_acls }

      it 'returns templates' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
