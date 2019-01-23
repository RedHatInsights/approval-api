# spec/requests/templates_spec.rb

RSpec.describe 'Templates API', :type => :request do
  # initialize test data
  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    before { get "#{api_version}/templates" }

    it 'returns templates' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    before { get "#{api_version}/templates/#{template_id}" }

    context 'when the record exists' do
      it 'returns the template' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(template_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end
end
