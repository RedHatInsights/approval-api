RSpec.describe Api::V1x0::ActionsController, :type => :request do
  include_context "approval_rbac_objects"
  let(:tenant) { create(:tenant) }

  let(:template) { create(:template) }
  let(:workflow) { create(:workflow, :template => template, :tenant => tenant) }

  let(:group) { instance_double(Group, :name => 'group1', :uuid => 'ref1') }
  let(:request) { create(:request, :with_context, :workflow => workflow, :group_ref => group.uuid, :state => 'notified', :tenant => tenant, :owner => "jdoe") }
  let(:actions) { create_list(:action, 10, :request => request, :tenant => tenant) }
  let(:id) { actions.first.id }

  let(:group2) { instance_double(Group, :name => 'group2', :uuid => 'ref2') }
  let(:request2) { create(:request, :with_context, :workflow => workflow, :group_ref => group2.uuid, :state => 'notified', :tenant => tenant, :owner => "jdoe") }
  let(:actions2) { create_list(:action, 10, :request => request2, :tenant => tenant) }
  let(:id2) { actions2.first.id }

  let(:roles_obj) { instance_double(Insights::API::Common::RBAC::Roles) }

  let(:setup_approver_role) do
    allow(rs_class).to receive(:paginate).and_return([group])
    allow(roles_obj).to receive(:roles).and_return([approver_role])
  end

  let(:setup_admin_role) do
    allow(rs_class).to receive(:paginate).and_return([])
    allow(roles_obj).to receive(:roles).and_return([admin_role])
  end

  let(:setup_requester_role) do
    allow(rs_class).to receive(:paginate).and_return([])
    allow(roles_obj).to receive(:roles).and_return([])
  end

  let(:api_version) { version }

  before do
    allow(Insights::API::Common::RBAC::Roles).to receive(:new).and_return(roles_obj)
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
  end

  describe 'GET /actions/:id' do
    context 'admin role' do
      before { setup_admin_role }

      context 'when the record exists' do
        it 'returns status code 200' do
          get "#{api_version}/actions/#{id}", :headers => default_headers

          expect(response).to have_http_status(200)

          action = actions.first

          expect(json).not_to be_empty
          expect(json['id']).to eq(action.id.to_s)
          expect(json['created_at']).to eq(action.created_at.iso8601)
        end
      end

      context 'when the record does not exist' do
        let!(:id) { 0 }

        it 'returns status code 404' do
          get "#{api_version}/actions/#{id}", :headers => default_headers

          expect(response).to have_http_status(404)
          expect(response.body).to match(/Couldn't find Action/)
        end
      end
    end

    context 'approver role' do
      before { setup_approver_role }

      context 'when approver can read' do
        it 'returns status code 200' do
          get "#{api_version}/actions/#{id}", :headers => default_headers

          expect(json['id']).to eq(id.to_s)
          expect(response).to have_http_status(200)
        end
      end

      context 'when approver cannot read' do
        it 'returns status code 403' do
          get "#{api_version}/actions/#{id2}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role cannot read' do
      before { setup_requester_role }

      it 'returns status code 403' do
        with_modified_env :APP_NAME => app_name do
          get "#{api_version}/actions/#{id}", :headers => default_headers
        end

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "GET /requests/:request_id/actions" do
    context 'admin role when request attributes are valid' do
      before do
        id
        setup_admin_role
      end

      it 'returns the actions' do
        get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(10)

        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before { setup_approver_role}

      context 'approver can read actions' do
        before { id }

        it 'returns the actions' do
          get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

          expect(json['links']).not_to be_nil
          expect(json['links']['first']).to match(/offset=0/)
          expect(json['data'].size).to eq(10)

          expect(response).to have_http_status(200)
        end
      end

      context 'approver cannot get actions' do
        before { id2 }

        it 'returns status code 403' do
          get "#{api_version}/requests/#{request2.id}/actions", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role cannot get actions' do
      before do
        id
        setup_requester_role
      end

      it 'returns status code 403' do
        get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /requests/:request_id/actions' do
    context 'admin role' do
      before { setup_admin_role }

      it 'can add valid operation' do
        test_attributes = {:operation => 'cancel', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(201)
      end

      it 'cannot add invalid operation' do
        test_attributes = {:operation => 'bad-op', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(400)
      end

      it 'cannot add unauthorized operation' do
        ['start', 'notify', 'skip'].each do |op|
          test_attributes = {:operation => op, :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'approver role for assigned request' do
      before { setup_approver_role }

      it 'can approve a request' do
        test_attributes = {:operation => 'approve', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(201)
      end

      it 'cannot add unauthorized operation' do
        ['start', 'notify', 'skip', 'cancel'].each do |op|
          test_attributes = {:operation => op, :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'approver role for unassigned request' do
      before { setup_approver_role }

      it 'cannot approve a request' do
        test_attributes = {:operation => 'approve', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request2.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'requester role' do
      before { setup_requester_role }

      it 'cannot add unauthorized operation' do
        ['start', 'notify', 'skip', 'approve', 'deny'].each do |op|
          test_attributes = {:operation => op, :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end

      it 'can cancel a request' do
        test_attributes = {:operation => 'cancel', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(201)
      end

      context 'with x-rh-random-access-key header' do
        let(:random_access_key) { RandomAccessKey.new(:access_key => 'unique-uid', :approver_name => 'Joe Smith') }
        let!(:request) { create(:request, :with_context, :state => 'started', :tenant_id => tenant.id, :owner => "jdoe", :random_access_keys => [random_access_key]) }

        it 'can notify a request with matched access key' do
          test_attributes = {:operation => 'notify', :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers.merge('x-rh-random-access-key' => random_access_key.access_key)

          expect(response).to have_http_status(201)
        end
      end
    end
  end
end
