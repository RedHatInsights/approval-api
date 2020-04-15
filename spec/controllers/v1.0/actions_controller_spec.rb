RSpec.describe Api::V1x0::ActionsController, :type => :request do
  include_context "approval_rbac_objects"
  let(:tenant) { create(:tenant) }

  let(:template) { create(:template) }
  let(:workflow) { create(:workflow, :template => template, :tenant => tenant) }

  let(:group) { instance_double(Group, :name => 'group1', :uuid => 'ref1') }
  let!(:request) { create(:request, :with_context, :workflow => workflow, :group_ref => group.uuid, :state => 'notified', :tenant => tenant, :owner => "jdoe") }
  let!(:actions) { create_list(:action, 10, :request => request, :tenant => tenant) }
  let(:id) { actions.first.id }

  let(:group2) { instance_double(Group, :name => 'group2', :uuid => 'ref2') }
  let(:request2) { create(:request, :with_context, :workflow => workflow, :group_ref => group2.uuid, :state => 'notified', :tenant => tenant, :owner => "jdoe2") }
  let(:actions2) { create_list(:action, 10, :request => request2, :tenant => tenant) }
  let(:id2) { actions2.first.id }
  let(:api_version) { version }

  describe 'GET /actions/:id' do
    let(:params) { { :id => "#{id}" } }

    context 'admin role' do
      before { admin_access }

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
      before do
        approver_access
        allow(user).to receive(:group_uuids).and_return([group.uuid])
      end

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
      before { user_access }

      context 'action that requester can read' do
        it 'returns status code 200' do
          get "#{api_version}/actions/#{id}", :headers => default_headers

          expect(json['id']).to eq(id.to_s)
          expect(response).to have_http_status(200)
        end
      end

      context 'action that requester cannot read' do
        it 'returns status code 403' do
          get "#{api_version}/actions/#{id2}", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe "GET /requests/:request_id/actions" do
    context 'admin role when request attributes are valid' do
      let(:params) { { :request_id => "#{request.id}" } }
      before { admin_access }

      it 'returns the actions' do
        get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

        expect(json['links']).not_to be_nil
        expect(json['links']['first']).to match(/offset=0/)
        expect(json['data'].size).to eq(10)

        expect(response).to have_http_status(200)
      end
    end

    context 'approver role' do
      before do
        approver_access
        allow(user).to receive(:group_uuids).and_return([group.uuid])
      end

      context 'approver can read actions' do
        let(:params) { { :request_id => "#{request.id}" } }

        it 'returns the actions' do
          get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

          expect(json['links']).not_to be_nil
          expect(json['links']['first']).to match(/offset=0/)
          expect(json['data'].size).to eq(10)

          expect(response).to have_http_status(200)
        end
      end

      context 'approver cannot get actions' do
        let(:params) { { :request_id => "#{request2.id}" } }

        it 'returns status code 403' do
          get "#{api_version}/requests/#{request2.id}/actions", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end

    context 'requester role cannot get actions' do
      let(:params) { { :request_id => "#{request.id}" } }
      before { user_access }

      context 'request that the requester made' do
        it 'gets actions of the request' do
          get "#{api_version}/requests/#{request.id}/actions", :headers => default_headers

          expect(response).to have_http_status(200)
          expect(json['data'].first['id']).to eq(id.to_s)
        end
      end

      context 'request that the requester did not make' do
        let(:params) { { :request_id => "#{request2.id}" } }

        it 'gets actions of the request' do
          get "#{api_version}/requests/#{request2.id}/actions", :headers => default_headers

          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'POST /requests/:request_id/actions' do
    let(:params) { { :request_id => "#{request.id}" } }

    before { allow(ActionPolicy).to receive(:new).and_return(policy) }

    context 'admin role' do
      before { admin_access }
      let(:policy) { instance_double(ActionPolicy, :create? => true) }

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

      context 'cannot add unauthorized operation' do
        let(:policy) { instance_double(ActionPolicy, :create? => false) }

        it 'return 403' do
          ['start', 'notify', 'skip'].each do |op|
            test_attributes = {:operation => op, :processed_by => 'abcd'}
            post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

            expect(response).to have_http_status(403)
          end
        end
      end
    end

    context 'approver role for assigned request' do
      before do
        approver_access
        allow(user).to receive(:group_uuids).and_return([group.uuid])
      end

      context 'can approve a request' do
        let(:policy) { instance_double(ActionPolicy, :create? => true) }

        it 'returns 201' do
          test_attributes = {:operation => 'approve', :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

          expect(response).to have_http_status(201)
        end
      end

      context 'cannot add unauthorized operation' do
        let(:policy) { instance_double(ActionPolicy, :create? => false) }

        it 'returns 403' do
          ['start', 'notify', 'skip', 'cancel'].each do |op|
            test_attributes = {:operation => op, :processed_by => 'abcd'}
            post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

            expect(response).to have_http_status(403)
          end
        end
      end
    end

    context 'approver role for unassigned request' do
      let(:policy) { instance_double(ActionPolicy, :create? => false) }
      before do
        approver_access
        allow(user).to receive(:group_uuids).and_return([group.uuid])
      end

      it 'cannot approve a request' do
        test_attributes = {:operation => 'approve', :processed_by => 'abcd'}
        post "#{api_version}/requests/#{request2.id}/actions", :params => test_attributes, :headers => default_headers

        expect(response).to have_http_status(403)
      end
    end

    context 'requester role' do
      before { user_access }

      context 'cannot add unauthorized operation' do
        let(:policy) { instance_double(ActionPolicy, :create? => false) }

        it 'returns 403' do
          ['start', 'notify', 'skip', 'approve', 'deny'].each do |op|
            test_attributes = {:operation => op, :processed_by => 'abcd'}
            post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

            expect(response).to have_http_status(403)
          end
        end
      end

      context 'can cancel a request' do
        let(:policy) { instance_double(ActionPolicy, :create? => true) }

        it 'returns 201' do
          test_attributes = {:operation => 'cancel', :processed_by => 'abcd'}
          post "#{api_version}/requests/#{request.id}/actions", :params => test_attributes, :headers => default_headers

          expect(response).to have_http_status(201)
        end
      end

      context 'with x-rh-random-access-key header' do
        let(:policy) { instance_double(ActionPolicy, :create? => true) }
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
