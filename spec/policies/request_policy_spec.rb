describe RequestPolicy do
  include_context "approval_rbac_objects"

  let(:group_uuid) { 'group-uuid' }
  let(:request) { create(:request, :state => 'notified', :group_ref => group_uuid) }
  let(:subject) { described_class.new(user, request) }

  describe 'with admin role' do
    before { admin_access }

    it 'returns true from #create?' do
      expect(subject.create?).to be_truthy
    end

    it 'returns true from #show?' do
      expect(subject.show?).to be_truthy
    end

    it 'returns all user capabilities from #user_capabilities' do
      result = { "approve"=> true, 
                 "cancel" => true, 
                 "create" => true, 
                 "deny"   => true, 
                 "memo"   => true, 
                 "show"   => true }

      expect(subject.user_capabilities).to eq(result)
    end
  end

  describe 'with approver role' do
    before { approver_access }

    it 'returns false from #create?' do
      expect(subject.create?).to be_falsey
    end

    describe '#show?' do
      context 'when has valid group_uuid' do
        it 'returns true' do
          allow(user).to receive(:group_uuids).and_return([group_uuid])
          expect(subject.show?).to be_truthy
        end
      end

      context 'when has invalid group_uuid' do
        it 'returns false' do
          allow(user).to receive(:group_uuids).and_return([])
          expect(subject.show?).to be_falsey
        end
      end

      context 'when request has invisible states' do
        before { request.update(:state => 'started') }
        it 'returns false' do
          allow(user).to receive(:group_uuids).and_return([group_uuid])
          expect(subject.show?).to be_falsey
        end
      end
    end

    it 'returns all user capabilities from #user_capabilities' do
      allow(user).to receive(:group_uuids).and_return([group_uuid])
      result = { "approve"=> true, 
                 "cancel" => false, 
                 "create" => false, 
                 "deny"   => true, 
                 "memo"   => true }
      expect(subject.user_capabilities).to include(result)
    end
  end

  describe 'with requester role' do
    before { user_access }

    it 'returns true from #create?' do
      expect(subject.create?).to be_truthy
    end

    describe '#show?' do
      around do |example|
        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          example.call
        end
      end

      it 'returns true' do
        expect(subject.show?).to be_truthy
      end

      context 'when not owner' do
        before { request.update(:owner => 'ugly name') }

        it 'returns false' do
          expect(subject.show?).to be_falsey
        end
      end
    end

    it 'returns all user capabilities from #user_capabilities' do
      result = { "approve"=> false, 
                 "cancel" => true, 
                 "create" => true, 
                 "deny"   => false, 
                 "memo"   => true }
      Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
        expect(subject.user_capabilities).to include(result)
      end
    end
  end
end
