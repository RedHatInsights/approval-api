# spec/requests/groups_spec.rb

RSpec.describe 'Groups API' do
  # Initialize the test data
  let!(:approvers) { create_list(:approver, 3) }
  let!(:other_approvers) { create_list(:approver, 3) }
  let!(:groups) { create_list(:group, 5, :approvers => approvers) }
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

  # Test suite for POST /groups
  describe 'POST /groups' do
    let(:valid_attributes) do
      { :name => 'Visit Narnia', :approver_ids => approvers.map(&:id) }
    end

    context 'when request attributes are valid' do
      before { post "#{api_version}/groups", :params => valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
        expect(Group.last.approvers.count).to eq(3)
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
    let(:valid_attributes) { { :name => 'Mozart', :approver_ids => [approvers.first.id, approvers.last.id] } }

    before { patch "#{api_version}/groups/#{id}", :params => valid_attributes }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Group.find(id)
        expect(updated_item.name).to match(/Mozart/)

        expect(updated_item.approvers.count).to eq(2)
        expect(updated_item.approvers.first.id).to eq(approvers.first.id)
        expect(updated_item.approvers.last.id).to eq(approvers.last.id)
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

  describe 'get /groups/:id/approvers' do
    before { get "#{api_version}/groups/#{id}/approvers", :headers => admin_encode_key }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns number of approvers' do
      group = Group.find(id)
      expect(group.approvers.count).to eq(3)
    end
  end

  describe 'post /groups/:id' do
    before { post "#{api_version}/groups/#{id}", :params => attributes, :headers => admin_encode_key }

    context 'when new approvers join in group' do
      let(:attributes) { { :operation => 'join_approvers', :parameters => { :approver_ids => [other_approvers.first.id, other_approvers.last.id] } } }

      it 'new approvers join in' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(5)
      end
    end

    context 'when some exsiting approvers join in group' do
      let(:attributes) { { :operation => 'join_approvers', :parameters => { :approver_ids => [approvers.first.id, other_approvers.last.id] } } }

      it 'new approvers join in' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(4)
        expect(group.approvers.last.id).to eq(other_approvers.last.id)
      end
    end

    context 'when exsiting approvers join in group' do
      let(:attributes) { { :operation => 'join_approvers', :parameters => { :approver_ids => [approvers.first.id, approvers.last.id] } } }

      it 'new approvers join in' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(3)
        expect(group.approvers.map(&:id)).to eq(approvers.map(&:id))
      end
    end

    context 'when exsiting approvers withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_approvers', :parameters => { :approver_ids => [approvers.first.id, approvers.last.id] } } }

      it 'exsiting approvers withdraw from group' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(1)
        expect(approvers.first.groups.count).to eq(4)
        expect(approvers.second.groups.count).to eq(5)
        expect(approvers.last.groups.count).to eq(4)
      end
    end

    context 'when some exsiting approvers withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_approvers', :parameters => { :approver_ids => [approvers.first.id, other_approvers.last.id] } } }

      it 'some exsiting approvers withdraw from group' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(2)
        expect(approvers.first.groups.count).to eq(4)
        expect(approvers.second.groups.count).to eq(5)
        expect(approvers.last.groups.count).to eq(5)
      end
    end

    context 'when non-exsiting approvers withdraw from group' do
      let(:attributes) { { :operation => 'withdraw_approvers', :parameters => { :approver_ids => [other_approvers.first.id, other_approvers.last.id] } } }

      it 'non-exsiting approvers withdraw from group' do
        group = Group.find(id)
        expect(group.approvers.count).to eq(3)
        expect(approvers.first.groups.count).to eq(5)
        expect(approvers.second.groups.count).to eq(5)
        expect(approvers.last.groups.count).to eq(5)
      end
    end

    context 'when invalid operation request in' do
      let(:attributes) { { :operation => 'bad_op', :parameters => { :approver_ids => [approvers.first.id, approvers.last.id] } } }

      it 'bad operation comes in' do
        expect(response).to have_http_status(403)
        expect(response.body).to match(/Invalid group operation: bad_op/)
      end
    end

    context 'when invalid parameters request in' do
      let(:attributes) { { :operation => 'join_approvers', :parameters => { :bad_ids => [approvers.first.id, approvers.last.id] } } }

      it 'bad operation comes in' do
        expect(response).to have_http_status(403)
        expect(response.body).to match(/Invalid group operation params:/)
      end
    end
  end
end
