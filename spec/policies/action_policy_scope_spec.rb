describe ActionPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => ['admin']) }
  let(:params) { { :request_id => request.id } }
  let(:user) { instance_double(UserContext, :params => params, :access => access, :rbac_enabled? => true) }
  let(:subject) { described_class.new(user, query) }

  describe '#resolve' do
    context 'when query is a scope' do
      let(:query) { Action.all }

      it 'returns actions' do
        expect(subject.resolve).to match_array(actions)
      end
    end

    context 'when query is model name' do
      let(:query) { Action }

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
