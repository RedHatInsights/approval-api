describe RequestPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:group_uuids) { ['group-uuid'] }
  let(:request) do
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) { create(:request, :state => 'notified') }
  end
  let!(:requests) { create_list(:request, 2) }
  let!(:sub_requests) { create_list(:request, 2, :parent_id => request.id) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true, :params => params, :group_uuids => group_uuids, :graphql_params => graphql_params) }

  let(:subject) { described_class.new(user, scope) }
  let(:headers_with_admin) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
  let(:headers_with_approver) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
  let(:headers_with_requester) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }
  let(:headers) { {:headers => req_headers, :original_url=>'url'} }

  describe '#resolve /requests' do
    let(:params) { {} }
    let(:scope) { Request }
    let(:graphql_params) { nil }

    context 'when admin role' do
      let(:req_headers) { headers_with_admin }
      before { allow(access).to receive(:scopes).and_return(['admin']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve.count).to eq(Request.where(:parent_id => nil).count)
        end
      end
    end

    context 'when approver role' do
      let(:req_headers) { headers_with_approver }
      before do
        sub_requests.first.update(:group_ref => group_uuids.first, :state => 'completed')
        requests.last.update(:group_ref => group_uuids.first, :state => 'notified')
        allow(access).to receive(:scopes).and_return(['group'])
      end

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve.sort).to eq(Request.where(:id => [sub_requests.first.id, requests.last.id]).sort)
        end
      end
    end

    context 'when requester role' do
      let(:req_headers) { headers_with_requester }
      before do
        allow(access).to receive(:scopes).and_return(['user'])
      end

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve.count).to eq(1)
          expect(subject.resolve.first).to eq(request)
        end
      end
    end
  end

  describe '#resolve GraphQL' do
    let(:params) { {} }
    let(:scope) { Request.all }

    context 'when graphql_query_by_id is not true' do
      let(:graphql_params) { double }
      before do
        allow(subject).to receive(:graphql_query_by_id?).and_return(false)
      end

      context 'when admin role' do
        let(:req_headers) { headers_with_admin }
        before { allow(access).to receive(:scopes).and_return(['admin']) }

        it 'returns requests' do
          Insights::API::Common::Request.with_request(headers) do
            expect(subject.resolve.count).to eq(Request.where(:parent_id => nil).count)
          end
        end
      end

      context 'when approver role' do
        let(:req_headers) { headers_with_approver }
        before do
          sub_requests.first.update(:group_ref => group_uuids.first, :state => 'completed')
          requests.last.update(:group_ref => group_uuids.first, :state => 'notified')
          allow(access).to receive(:scopes).and_return(['group'])
        end

        it 'returns requests' do
          Insights::API::Common::Request.with_request(headers) do
            expect(subject.resolve.count).to eq(2)
          end
        end
      end

      context 'when requester role' do
        let(:req_headers) { headers_with_requester }
        before do
          allow(access).to receive(:scopes).and_return(['user'])
        end

        it 'returns requests' do
          Insights::API::Common::Request.with_request(headers) do
            expect(subject.resolve.count).to eq(1)
            expect(subject.resolve.first).to eq(request)
          end
        end
      end
    end

    context 'when graphql_query_by_id is true' do
      let(:graphql_params) { double("graphql_params", :id => request.id) }
      before do
        allow(subject).to receive(:graphql_query_by_id?).and_return(true)
      end

      context 'when admin role' do
        let(:req_headers) { headers_with_admin }
        before { allow(access).to receive(:scopes).and_return(['admin']) }

        it 'returns requests' do
          Insights::API::Common::Request.with_request(headers) do
            expect(subject.resolve.count).to eq(5)
          end
        end
      end
    end
  end

  describe '#resolve /requests/#{id}/requests' do
    let!(:scope) { request.requests }
    let(:params) { {:request_id => request.id} }
    let(:graphql_params) { nil }

    context 'when admin role' do
      let(:req_headers) { headers_with_admin }
      before { allow(access).to receive(:scopes).and_return(['admin']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve).to match_array(sub_requests)
        end
      end
    end

    context 'when regular user role' do
      let(:req_headers) { headers_with_requester }
      before { allow(access).to receive(:scopes).and_return(['user']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve).to match_array(sub_requests)
        end
      end
    end

  end
end
