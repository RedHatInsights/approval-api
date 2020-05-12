describe RequestPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:group_uuid) { 'group-uuid' }
  let(:requests) do
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
      create_list(:request, 2, :state => 'notified', :group_ref => group_uuid)
    end
  end
  let!(:sub_requests) { create_list(:request, 2, :parent_id => requests.first.id) }
  let(:subject) { described_class.new(user, Request) }

  describe '#resolve_scope' do
    context 'when user params contains request_id' do
      let(:params) { { :request_id => requests.first.id } }

      it 'returns the scope with admin role' do
        admin_access
        expect(subject.resolve_scope).to match_array(sub_requests)
      end

      context 'with approver role' do
        before { approver_access }

        it 'returns scope for valid group uuid' do
          allow(user).to receive(:group_uuids).and_return([group_uuid])
          expect(subject.resolve_scope).to match_array(sub_requests)
        end

        it 'raises an error for invalid group uuid' do
          allow(user).to receive(:group_uuids).and_return([])
          expect { subject.resolve_scope }.to raise_error(Exceptions::NotAuthorizedError)
        end
      end

      context 'with user role' do
        before { user_access }

        it 'returns requests' do
          Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
            expect(subject.resolve_scope).to match_array(sub_requests)
          end
        end

        context 'when owner is wrong' do
          before { requests.first.update(:owner => 'ugly name') }

          it 'raises an error' do
            Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
              expect { subject.resolve_scope }.to raise_error(Exceptions::NotAuthorizedError)
            end
          end
        end
      end
    end

    context 'when user params do not contain request_id' do
      let(:admin_header) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
      let(:approver_header) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
      let(:user_header) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }
      let(:header) { {:headers => persona_header, :original_url=>'url'} }
      let!(:other_requests) { create_list(:request, 2) }

      context 'with admin role' do
        let(:persona_header) { admin_header }

        it 'returns requests' do
          admin_access

          Insights::API::Common::Request.with_request(header) do
            expect(subject.resolve_scope).to match_array(requests + other_requests)
          end
        end
      end

      context 'with approver role' do
        let(:persona_header) { approver_header }

        it 'returns requests' do
          allow(user).to receive(:group_uuids).and_return([group_uuid])
          approver_access

          Insights::API::Common::Request.with_request(header) do
            expect(subject.resolve_scope).to match_array(requests)
          end
        end

        it 'returns empty requests' do
          allow(user).to receive(:group_uuids).and_return([])
          approver_access

          Insights::API::Common::Request.with_request(header) do
            expect(subject.resolve_scope).to eq([])
          end
        end
      end

      context 'with user role' do
        let(:persona_header) { user_header }

        it 'returns requests' do
          user_access

          Insights::API::Common::Request.with_request(header) do
            expect(subject.resolve_scope).to match_array(requests)
          end
        end
      end

      context 'when persona is invalid' do
        let(:persona_header) do
          RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/invalid')
        end

        it 'raises an error' do
          admin_access

          Insights::API::Common::Request.with_request(header) do
            expect { subject.resolve_scope }.to raise_error(Exceptions::NotAuthorizedError)
          end
        end
      end
    end
  end
end
