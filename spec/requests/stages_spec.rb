# spec/requests/stages_spec.rb

RSpec.describe 'Stages API' do
  let!(:template) { create(:template) }
  let!(:workflow) { create(:workflow, :template_id => template.id) }
  let!(:request) { create(:request, :workflow_id => workflow.id) }
  let(:request_id) { request.id }

  let!(:group) { create(:group) }
  let!(:stages) { create_list(:stage, 5, :group_id => group.id, :request_id => request.id) }
  let(:id) { stages.first.id }

  describe 'GET /stages' do
    before { get "#{api_version}/stages" }

    it 'returns stages' do
      expect(response).to have_http_status(200)
      expect(json.size).to eq(5)
    end
  end

  # Test suite for GET /stages/:id
  describe 'GET /stages/:id' do
    before { get "#{api_version}/stages/#{id}" }

    context 'when the record exists' do
      it 'returns the stage' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Stage/)
      end
    end
  end

  # Test suite for GET /requests/:request_id/stages
  describe 'GET /requests/:request_id/stages' do
    before { get "#{api_version}/requests/#{request_id}/stages" }

    context 'when the record exists' do
      it 'returns the stages' do
        expect(json).not_to be_empty
        expect(json.size).to eq(5)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:request_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Request/)
      end
    end
  end
end
