describe ActionPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:request) { create(:request, :group_ref => group_uuid) }
  let(:actions) { create_list(:action, 3, :request => request) }
  let(:subject) { described_class.new(user, Action) }
  let(:group_uuid) { 'group-uuid' }

  describe '#resolve_scope' do
    context 'when user params contain request_id' do
      let(:params) { { :request_id => request.id } }

      it 'returns actions with admin role' do
        admin_access
        expect(subject.resolve_scope).to match_array(actions)
      end

      it 'returns actions with approver role' do
        approver_access
        allow(user).to receive(:group_uuids).and_return([group_uuid])
        request.update(:state => 'notified')

        expect(subject.resolve_scope).to match_array(actions)
      end

      it 'returns actions with requestor role' do
        user_access
        request.update(:owner => 'jdoe')

        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          expect(subject.resolve_scope).to match_array(actions)
        end
      end
    end

    context 'when user params dont contain request_id' do
      let(:params) { { :id => request.id } }

      it 'raises an error' do
        expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
