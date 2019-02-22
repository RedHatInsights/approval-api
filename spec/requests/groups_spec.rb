# spec/requests/groups_spec.rb

RSpec.describe 'Groups API' do
  # Initialize the test data
  let!(:users) { create_list(:user, 3) }
  let!(:other_users) { create_list(:user, 3) }
  let!(:groups) { create_list(:group, 5, :users => users) }
  let(:id) { groups.first.id }

  # Test suite for GET /groups
  describe 'GET /groups' do
    before { get "#{api_version}/groups" }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all groups' do
      expect(json).not_to be_empty
      expect(json.size).to eq(5)
    end
  end

  # Test suite for GET /workflows/:workflow_id/groups
  describe 'GET /workflows/:workflow_id/groups' do
    before { get "#{api_version}/workflows/#{workflow_id}/groups" }

    context 'when workflow exists' do
      let!(:template) { create(:template) }
      let!(:workflow) { create(:workflow, :template => template, :groups => groups) }
      let!(:workflow_id) { workflow.id }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all groups in the workflow' do
        expect(json.size).to eq(5)
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

  # Test suite for POST /groups
  describe 'POST /groups' do
    let(:valid_attributes) do
      { :name => 'Visit Narnia', :user_ids => users.map(&:id) }
    end

    context 'when request attributes are valid' do
      before { post "#{api_version}/groups", :params => valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
        expect(Group.last.users.count).to eq(3)
      end
    end

    context 'when an invalid request' do
      before { post "#{api_version}/groups", :params => {} }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for patch /groups/:id
  describe 'patch /groups/:id' do
    let(:valid_attributes) { { :name => 'Mozart', :user_ids => [users.first.id, users.last.id] } }

    before { patch "#{api_version}/groups/#{id}", :params => valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Group.find(id)
        expect(updated_item.name).to match(/Mozart/)

        expect(updated_item.users.count).to eq(2)
        expect(updated_item.users.first.id).to eq(users.first.id)
        expect(updated_item.users.last.id).to eq(users.last.id)
      end
    end

    context 'when the item does not exist' do
      let!(:id) { 0 }

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
    before { delete "#{api_version}/groups/#{id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'get /groups/:id/users' do
    before { get "#{api_version}/groups/#{id}/users" }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns number of users' do
      group = Group.find(id)
      expect(group.users.count).to eq(3)
    end
  end

  describe 'post /groups/:id' do
    before { post "#{api_version}/groups/#{id}", :params => attributes }

    context 'when new users join in group' do
      let(:attributes) { { :operation => 'join_users', :parameters => { :user_ids => [other_users.first.id, other_users.last.id] } } }

      it 'new users join in' do
        group = Group.find(id)
        expect(group.users.count).to eq(5)
      end
    end

    context 'when some exsiting users join in group' do
      let(:attributes) { { :operation => 'join_users', :parameters => { :user_ids => [users.first.id, other_users.last.id] } } }

      it 'new users join in' do
        group = Group.find(id)
        expect(group.users.count).to eq(4)
        expect(group.users.last.id).to eq(other_users.last.id)
      end
    end

    context 'when exsiting users join in group' do
      let(:attributes) { { :operation => 'join_users', :parameters => { :user_ids => [users.first.id, users.last.id] } } }

      it 'new users join in' do
        group = Group.find(id)
        expect(group.users.count).to eq(3)
        expect(group.users.map(&:id)).to eq(users.map(&:id))
      end
    end

    context 'when exsiting users withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_users', :parameters => { :user_ids => [users.first.id, users.last.id] } } }

      it 'exsiting users withdraw from group' do
        group = Group.find(id)
        expect(group.users.count).to eq(1)
        expect(users.first.groups.count).to eq(4)
        expect(users.second.groups.count).to eq(5)
        expect(users.last.groups.count).to eq(4)
      end
    end

    context 'when some exsiting users withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_users', :parameters => { :user_ids => [users.first.id, other_users.last.id] } } }

      it 'some exsiting users withdraw from group' do
        group = Group.find(id)
        expect(group.users.count).to eq(2)
        expect(users.first.groups.count).to eq(4)
        expect(users.second.groups.count).to eq(5)
        expect(users.last.groups.count).to eq(5)
      end
    end

    context 'when non-exsiting users withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_users', :parameters => { :user_ids => [other_users.first.id, other_users.last.id] } } }

      it 'non-exsiting users withdraw from group' do
        group = Group.find(id)
        expect(group.users.count).to eq(3)
        expect(users.first.groups.count).to eq(5)
        expect(users.second.groups.count).to eq(5)
        expect(users.last.groups.count).to eq(5)
      end
    end

    context 'when invalid operation request in' do
      let(:attributes) { { :operation => 'bad_op', :parameters => { :user_ids => [users.first.id, users.last.id] } } }

      it 'bad operation comes in' do
        expect(response).to have_http_status(403)
        expect(response.body).to match(/Invalid group operation: bad_op/)
      end
    end

    context 'when invalid parameters request in' do
      let(:attributes) { { :operation => 'join_users', :parameters => { :bad_ids => [users.first.id, users.last.id] } } }

      it 'bad operation comes in' do
        expect(response).to have_http_status(403)
        expect(response.body).to match(/Invalid group operation params:/)
      end
    end
  end

  describe 'GET /groups with major version specified' do
    before { get "/api/v0/groups" }

    it 'returns redirect status' do
      expect(response).to have_http_status(301)
      expect(response.headers["Location"]).to eq "#{api_version}/groups"
    end
  end
end
