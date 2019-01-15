# spec/requests/approvers_spec.rb

RSpec.describe 'Approvers API' do
  # Initialize the test data
  let!(:groups) { create_list(:group, 3) }
  let!(:approvers) { create_list(:approver, 5, :group_ids => groups.map(&:id)) }
  let(:id) { approvers.first.id }
  let!(:workflow) { create(:workflow, :groups => groups) }
  let(:attribute) do
    { :requester => '1234', :name => 'Visit Narnia',
      :content => JSON.generate('{ "disk" => "100GB" }') }
  end
  let!(:request) { RequestCreateService.new(workflow.id).create(attribute) }

  let(:admin_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWV9fQ==\n' } }
  let(:user_encode_key) { { :'x-rh-auth-identity' => 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlfX0=\n' } }

  # Test suite for GET /approvers
  describe 'GET /approvers' do
    before { get "#{api_version}/approvers", :headers => admin_encode_key }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all approvers' do
      expect(json).not_to be_empty
      expect(json.size).to eq(5)
    end
  end

  describe 'GET /approvers/:id/groups' do
    before { get "#{api_version}/approvers/#{id}/groups", :headers => admin_encode_key }

    it 'return number of groups' do
      expect(Approver.find(id).groups.count).to eq(3)
    end
  end

  describe 'GET /approvers/:id/requests' do
    before { get "#{api_version}/approvers/#{id}/requests", :headers => admin_encode_key }

    it 'return number of groups' do
      expect(Approver.find(id).requests.count).to eq(1)
    end
  end

  # Test suite for POST /approvers
  describe 'POST /approvers' do
    let(:valid_attributes) { { :email => '123@abc.com', :group_ids => groups.map(&:id) } }

    context 'when request attributes are valid' do
      before { post "#{api_version}/approvers", :params => valid_attributes, :headers => admin_encode_key }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "#{api_version}/approvers", :params => {}, :headers => admin_encode_key }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: Email can't be blank/)
      end
    end
  end

  # Test suite for patch /approvers/:id
  describe 'patch /approvers/:id' do
    let(:valid_attributes) { { :group_ids => [groups.first.id, groups.last.id] } }

    before { patch "#{api_version}/approvers/#{id}", :params => valid_attributes, :headers => admin_encode_key }

    context 'when item exists' do
      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end

      it 'updates the item' do
        updated_item = Approver.find(id)

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
        expect(response.body).to match(/Couldn't find Approver/)
      end
    end
  end

  # Test suite for DELETE /approvers/:id
  describe 'DELETE /approvers/:id' do
    before { delete "#{api_version}/approvers/#{id}", :headers => admin_encode_key }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
