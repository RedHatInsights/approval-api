# spec/requests/requests_spec.rb

RSpec.describe 'Requests API' do
  # Initialize the test data
  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, :template_id => template.id) }
  let(:workflow_id) { workflow.id }
  let!(:requests) { create_list(:request, 2, :workflow_id => workflow.id) }
  let(:id) { requests.first.id }
  let!(:requests_with_same_state) { create_list(:request, 2, :state => 'notified', :workflow_id => workflow.id) }
  let!(:requests_with_same_decision) { create_list(:request, 2, :decision => 'approved', :workflow_id => workflow.id) }

  # Test suite for GET /workflows/:workflow_id/requests
  describe 'GET /workflows/:workflow_id/requests' do
    before { get "#{api_version}/workflows/#{workflow_id}/requests" }

    context 'when workflow exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all workflow requests' do
        expect(json.size).to eq(6)
      end
    end

    context 'when workflow does not exist' do
      let!(:workflow_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for GET /requests
  describe 'GET /requests' do
    before { get "#{api_version}/requests" }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(6)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests?state=
  describe 'GET /requests?state=notified' do
    before { get "#{api_version}/requests?state=notified" }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(2)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests?decision=
  describe 'GET /requests?decision=approved' do
    before { get "#{api_version}/requests?decision=approved" }

    it 'returns requests' do
      expect(json).not_to be_empty
      expect(json.size).to eq(2)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /requests/:id
  describe 'GET /requests/:id' do
    before { get "#{api_version}/requests/#{id}" }

    context 'when the record exist' do
      it 'returns the request' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when request does not exist' do
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end

  # Test suite for POST /workflows/:workflow_id/requests
  describe 'POST /workflows/:workflow_id/requests' do
    let(:item) { { 'disk' => '100GB' } }
    let(:valid_attributes) { { :requester => '1234', :name => 'Visit Narnia', :content => JSON.generate(item) } }

    context 'when request attributes are valid' do
      before { post "#{api_version}/workflows/#{workflow_id}/requests", :params => valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end
  end
end
