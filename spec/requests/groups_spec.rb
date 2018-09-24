# spec/requests/groups_spec.rb
require 'rails_helper'

RSpec.describe 'Groups API' do
  # Initialize the test data
  let!(:groups) { create_list(:group, 20) }
  let(:id) { groups.first.id }

  # Test suite for GET /groups
  describe 'GET /groups' do
    before { get "/groups" }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all groups' do
      expect(json).not_to be_empty
      expect(json.size).to eq(20)
    end
  end

  # Test suite for GET /groups/:id
  describe 'GET /groups/:id' do
    before { get "/groups/#{id}" }

    context 'when the group exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the group' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(id)
      end
    end

    context 'when group does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Group/)
      end
    end
  end

  # Test suite for POST /groups
  describe 'POST /groups' do
    let(:valid_attributes) { { name: 'Visit Narnia', email: '123@abc.com' } }

    context 'when request attributes are valid' do
      before { post "/groups", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/groups", params: {} }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for PUT /workflows/:workflow_id/groups/:id
  describe 'PUT /groups/:id' do
    let(:valid_attributes) { { name: 'Mozart' } }

    before { put "/groups/#{id}", params: valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Group.find(id)
        expect(updated_item.name).to match(/Mozart/)
      end
    end

    context 'when the item does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Group/)
      end
    end
  end

  # Test suite for DELETE /groups/:id
  describe 'DELETE /groups/:id' do
    before { delete "/groups/#{id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
