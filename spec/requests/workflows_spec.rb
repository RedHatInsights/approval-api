# spec/requests/workflows_spec.rb

RSpec.describe 'Workflows API' do
  # Initialize the test data
  let!(:template) { create(:template) }
  let(:template_id) { template.id }
  let!(:workflows) { create_list(:workflow, 20, :template_id => template.id) }
  let(:id) { workflows.first.id }

  let(:user_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }
  let(:admin_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }

  describe 'GET /templates/:template_id/workflows' do
    before { get "#{api_version}/templates/#{template_id}/workflows", :headers => admin_encode_key }

    context 'when template exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all template workflows' do
        expect(json.size).to eq(20)
      end
    end

    context 'when template does not exist' do
      let(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end

  describe 'GET /workflows' do
    before { get "#{api_version}/workflows", :headers => admin_encode_key }

    context 'when no relate wiht template'
    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all template workflows' do
      expect(json.size).to eq(20)
    end
  end

  describe 'GET /workflows/:id' do
    before { get "#{api_version}/workflows/#{id}", :headers => admin_encode_key }

    context 'when the record exists' do
      it 'returns the workflow' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:id) { 100 }
      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for POST /templates/:template_id/workflows
  describe 'POST /templates/:template_id/workflows' do
    let(:valid_attributes) { { :name => 'Visit Narnia', :done => false } }

    context 'when request attributes are valid' do
      before { post "#{api_version}/templates/#{template_id}/workflows", :params => valid_attributes, :headers => admin_encode_key }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "#{api_version}/templates/#{template_id}/workflows", :params => {}, :headers => admin_encode_key }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for PUT /workflows/:id
  describe 'PUT /workflows/:id' do
    let(:valid_attributes) { { :name => 'Mozart' } }

    before { put "#{api_version}/workflows/#{id}", :params => valid_attributes, :headers => admin_encode_key }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Workflow.find(id)
        expect(updated_item.name).to match(/Mozart/)
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Workflow/)
      end
    end
  end

  # Test suite for DELETE /workflows/:id
  describe 'DELETE /workflows/:id' do
    before { delete "#{api_version}/workflows/#{id}", :headers => admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
