describe ActionPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:subject) { described_class.new(instance_double(UserContext), query) }

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
