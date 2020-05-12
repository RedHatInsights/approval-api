describe ApplicationPolicy::Scope do
  include_context "approval_rbac_objects"

  let(:subject) { described_class.new(user, scope) }

  shared_examples_for 'test_scopes_with_errors' do
    it "resolves the scope with admin access" do
      admin_access
      expect(subject.resolve).to eq(scope)
    end

    it "raises an error with approver access" do
      approver_access
      expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
    end

    it "raises an error with user access" do
      user_access
      expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
    end
  end

  shared_examples_for 'test_scopes_with_one_error' do
    it "resolves the scope with admin access" do
      admin_access
      expect(subject.resolve).to eq(scope)
    end

    it "raises an error with approver access" do
      approver_access
      expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
    end

    it "resolves the scope with user access" do
      user_access
      expect(subject.resolve).to eq(scope)
    end
  end

  shared_examples_for 'test_scopes_without_errors' do
    it "resolves the scope with admin access" do
      admin_access
      expect(subject.resolve).to eq(scope)
    end

    it "resolves the scope with approver access" do
      approver_access
      expect(subject.resolve).to eq(scope)
    end

    it "resolves the scope with user access" do
      user_access
      expect(subject.resolve).to eq(scope)
    end
  end

  describe "#resolve" do
    context "when rbac_enabled is false" do
      let(:scope) { Request.all }
      before { allow(user).to receive(:rbac_enabled?).and_return(false) }

      it "resolves the scope" do
        expect(subject.resolve).to eq(scope)
      end
    end

    context 'when graphql_query_by_id? is true' do
      let(:scope) { Request.all }
      let(:request) { create(:request) }
      let(:graphql_params) { double(:id => request.id) }

      it 'returns scope for admin role' do
        admin_access
        expect(subject.resolve).to eq(scope)
      end

      it 'raises an error for user role' do
        user_access

        Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) do
          expect { subject.resolve }.to raise_error(Exceptions::NotAuthorizedError)
        end
      end
    end

    context "Template" do
      let(:scope) { Template.all }

      it_behaves_like "test_scopes_with_errors"
    end

    context "Workflow" do
      let(:scope) { Workflow.all }

      it_behaves_like "test_scopes_with_one_error"
    end

    context "Request" do
      let(:scope) { Request.all }

      it_behaves_like "test_scopes_without_errors"
    end

    context "Action" do
      let(:scope) { Action.all }

      it_behaves_like "test_scopes_without_errors"
    end
  end

  describe "#resolve_scope" do
    let(:scope) { Template.all }

    it_behaves_like "test_scopes_with_errors"
  end
end
