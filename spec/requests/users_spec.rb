# spec/requests/users_spec.rb

RSpec.describe 'Users API' do
  # Initialize the test data
  let!(:groups) { create_list(:group, 3) }
  let!(:users) { create_list(:user, 5, :group_ids => groups.map(&:id)) }
  let(:id) { users.first.id }
  let!(:workflow) { create(:workflow, :groups => groups) }
  let(:attribute) do
    { :requester => '1234', :name => 'Visit Narnia',
      :content => JSON.generate('{ "disk" => "100GB" }') }
  end
  let!(:request) { RequestCreateService.new(workflow.id).create(attribute) }

  # Test suite for GET /users
  describe 'GET /users' do
    before { get "#{api_version}/users" }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all users' do
      expect(json).not_to be_empty
      expect(json.size).to eq(5)
    end
  end

  describe 'GET /users/:id/groups' do
    before { get "#{api_version}/users/#{id}/groups" }

    it 'return number of groups' do
      expect(User.find(id).groups.count).to eq(3)
    end
  end

  describe 'GET /users/:id/requests' do
    before { get "#{api_version}/users/#{id}/requests" }

    it 'return number of groups' do
      expect(User.find(id).requests.count).to eq(1)
    end
  end

  # Test suite for POST /users
  describe 'POST /users' do
    let(:valid_attributes) { { :email => '123@abc.com', :group_ids => groups.map(&:id) } }

    context 'when request attributes are valid' do
      before { post "#{api_version}/users", :params => valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "#{api_version}/users", :params => {} }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Email can't be blank/)
      end
    end
  end

  # Test suite for patch /users/:id
  describe 'patch /users/:id' do
    let(:valid_attributes) { { :group_ids => [groups.first.id, groups.last.id] } }

    before { patch "#{api_version}/users/#{id}", :params => valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = User.find(id)

        expect(updated_item.groups.count).to eq(2)
        expect(updated_item.groups.first.id).to eq(groups.first.id)
        expect(updated_item.groups.last.id).to eq(groups.last.id)
      end
    end

    context 'when the item does not exist' do
      let!(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find User/)
      end
    end
  end

  # Test suite for DELETE /users/:id
  describe 'DELETE /users/:id' do
    before { delete "#{api_version}/users/#{id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
