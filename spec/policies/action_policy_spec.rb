describe ActionPolicy do
  include_context "approval_rbac_objects"

  let(:request) { create(:request) }
  let(:key) { create(:random_access_key, :request => request) }
  let(:action) { create(:action, :request => request) }
  let(:subject) { described_class.new(user, action) }

  describe 'with admin role' do
    before { admin_access }

    describe '#show?' do
      it 'returns true' do
        expect(subject.show?).to be_truthy
      end
    end

    describe '#create?' do
      let(:subject) { described_class.new(user, Action) }
      let(:params) { ActionController::Parameters.new({ :operation => operation, :request_id => request.id }) }
      let(:request_params) { { 'x-rh-random-access-key' => nil } }

      before do
        allow(user).to receive_message_chain('request.headers').and_return(request_params)
      end

      context 'when operation is approve' do
        let(:operation) { 'approve' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is deny' do
        let(:operation) { 'deny' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is cancel' do
        let(:operation) { 'cancel' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is memo' do
        let(:operation) { 'memo' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when invalid operations' do
        let(:operation) { 'start' }

        it 'returns false' do
          expect(subject.create?).to be_falsey
        end
      end

      context 'when uuid is present' do
        let(:operation) { 'notify' }
        let(:request_params) { { 'x-rh-random-access-key' => key.access_key } }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when wrong access_key is present' do
        let(:operation) { 'notify' }
        let(:request_params) { { 'x-rh-random-access-key' => 'wrong_key' } }

        it 'returns false' do
          expect(subject.create?).to be_falsey
        end
      end
    end
  end

  describe 'with approver role' do
    let(:group_uuid) { 'group-uuid' }

    before do
      approver_access
      allow(user).to receive(:group_uuids).and_return([group_uuid])
    end

    describe '#show?' do
      it 'returns true for notified state' do
        request.update(:group_ref => group_uuid, :state => 'notified')
        expect(subject.show?).to be_truthy
      end

      it 'returns true for completed state' do
        request.update(:group_ref => group_uuid, :state => 'completed')
        expect(subject.show?).to be_truthy
      end

      it 'returns false for unapprovable states' do
        request.update(:group_ref => group_uuid, :state => 'pending')
        expect(subject.show?).to be_falsey
      end
    end

    describe '#create?' do
      let(:subject) { described_class.new(user, Action) }
      let(:params) { ActionController::Parameters.new({ :operation => operation, :request_id => request.id }) }
      let(:request_params) { { 'x-rh-random-access-key' => nil } }

      before do
        allow(user).to receive_message_chain('request.headers').and_return(request_params)
      end

      context 'when operation is approve' do
        let(:operation) { 'approve' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is deny' do
        let(:operation) { 'deny' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is memo' do
        let(:operation) { 'memo' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operation is cancel' do
        let(:operation) { 'cancel' }

        it 'returns false' do
          expect(subject.create?).to be_falsey
        end
      end
    end
  end

  describe 'with requester role' do
    before { user_access }

    describe '#show?' do
      around do |example|
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          example.call
        end
      end

      it 'returns true for valid owner' do
        expect(subject.show?).to be_truthy
      end

      it 'returns false for invalid owner' do
        request.update(:owner => 'bad people')
        expect(subject.show?).to be_falsey
      end
    end

    describe '#create?' do
      let(:subject) { described_class.new(user, Action) }
      let(:params) { ActionController::Parameters.new({ :operation => operation, :request_id => request.id }) }
      let(:request_params) { { 'x-rh-random-access-key' => nil } }

      before do
        allow(user).to receive_message_chain('request.headers').and_return(request_params)
      end

      context 'when operation is cancel' do
        let(:operation) { 'cancel' }

        it 'returns true' do
          expect(subject.create?).to be_truthy
        end
      end

      context 'when operations are invalid' do
        let(:operation) { 'approve' }

        it 'returns false' do
          expect(subject.create?).to be_falsey
        end
      end
    end
  end
end
