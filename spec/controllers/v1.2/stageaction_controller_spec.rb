RSpec.describe Api::V1x2::StageactionController, :type => [:v1x2, :request, :controller] do
  let(:key) { create(:random_access_key, :access_key => 'unique-123', :approver_name => 'Joe Smith') }
  let!(:approval_request) { create(:request, :with_tenant, :with_context, :random_access_keys => [key]) }

  let(:test_env) do
    {
      :APPROVAL_WEB_LOGO    => 'http://localhost/logo',
      :APPROVAL_WEB_PRODUCT => 'http://localhost/product'
    }
  end

  describe 'GET /stageaction/:id' do
    it 'returns 200' do
      with_modified_env test_env do
        get "#{api_version}/stageaction/#{key.access_key}"

        expect(response.status).to eq(200)
      end
    end

    context 'when access key is invalid' do
      it 'returns 500' do
        get "#{api_version}/stageaction/invalid-access-key"

        expect(response.status).to eq(500)
        expect(response.body).to match("Reason: Your request is either expired or has been processed!")
      end
    end
  end

  describe 'PATCH /stageaction/:id' do
    context 'when operaton is memo/deny' do
      it 'successfully adds an action' do
        patch "#{api_version}/stageaction/#{key.access_key}", :params => {:commit => 'Memo', :message => 'hello'}

        expect(approval_request.actions.count).to eq(1)
        expect(approval_request.actions.first.operation).to eq("memo")
        expect(approval_request.actions.first.comments).to eq("hello")
      end

      it 'returns 400 if message is missing' do
        patch "#{api_version}/stageaction/#{key.access_key}", :params => {:commit => 'Deny'}

        expect(response.status).to eq(400)
      end
    end

    context 'when operaton is approve' do
      it 'successfully adds an action' do
        approval_request.update(:state => Request::NOTIFIED_STATE)
        patch "#{api_version}/stageaction/#{key.access_key}", :params => {:commit => 'Approve'}

        expect(approval_request.actions.count).to eq(1)
        expect(approval_request.actions.first.operation).to eq("approve")
      end
    end

    context 'when state is invalid' do
      it 'raises an InvalidStateTransitionError' do
        patch "#{api_version}/stageaction/#{key.access_key}", :params => {:commit => 'Approve'}

        expect(response.status).to eq(400)
        expect(response.body).to match(/Exceptions::InvalidStateTransitionError: Current request is not in notified state/)
      end
    end

    context 'when params is missing' do
      it 'returns 400' do
        patch "#{api_version}/stageaction/#{key.access_key}"

        expect(response.status).to eq(400)
      end
    end
  end

  describe '#set_order' do
    before { subject.instance_variable_set(:@request, approval_request) }

    it 'sets order date and time in correct format' do
      order = subject.send(:set_order)

      expect(order[:order_date]).to match(/\d+ [a-zA-Z]+ \d+/)
      expect(order[:order_time]).to match(/\d+:\d+ UTC/)
    end
  end
end
