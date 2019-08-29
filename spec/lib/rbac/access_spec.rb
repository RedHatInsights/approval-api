describe RBAC::Access do
  include_context "rbac_objects"
  let!(:workflows) { create_list(:workflow, 2) }
  let!(:request) { create(:request, :workflow_id => workflows.first.id, :owner => 'adam') }
  let!(:requests) { create_list(:request, 2, :workflow_id => workflows.last.id, :owner => 'jdoe') }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  shared_examples_for ".acls" do
    it "validate acls" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return(acls)

        expect(described_class.acls(res, verb).count).to equal(num)
      end
    end
  end

  shared_examples_for ".approver_id_list" do
    it "approver id list" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {:scope => 'principal'}, app_name).and_return(acls)

        expect(described_class.approver_id_list(res)).to eq(ids)
      end
    end
  end

  context "when resources are same" do
    let(:verb) { "create" }
    let(:res) { "requests" }
    let(:num) { 2 }
    let(:acls) { [access1, access2, access3, access4] }
    it_behaves_like ".acls"
  end

  context "when actions are same" do
    let(:verb) { "read" }
    let(:res) { "stages" }
    let(:num) { 1 }
    let(:acls) { [access1, access2, access3, access5] }
    it_behaves_like ".acls"
  end

  context "approver_id_list" do
    let!(:stages1) { create_list(:stage, 2, :state => 'notified', :request_id => request.id) }
    let!(:stage2) { create(:stage, :state => 'notified', :request_id => requests.second.id) }
    let!(:actions1) { create_list(:action, 2, :stage_id => stages1.first.id) }
    let!(:actions2) { create_list(:action, 3, :stage_id => stages1.last.id) }
    let!(:actions3) { create_list(:action, 4, :stage_id => stage2.id) }

    let(:approver_filter) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflows.first.id) }
    let(:approver_resource_def) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter) }
    let(:approver_access) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:approve", :resource_definitions => [approver_resource_def]) }

    let(:approver_filter_2) { instance_double(RBACApiClient::ResourceDefinitionFilter, :key => 'id', :operation => 'equal', :value => workflows.last.id) }
    let(:approver_resource_def_2) { instance_double(RBACApiClient::ResourceDefinition, :attribute_filter => approver_filter_2) }
    let(:approver_access_2) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:workflows:approve", :resource_definitions => [approver_resource_def_2]) }

    describe "for first approver requests" do
      let(:acls) { [approver_access] }
      let(:res) { "requests" }
      let(:ids) { [request.id] }

      it_behaves_like ".approver_id_list"
    end

    describe "for first approver stages" do
      let(:acls) { [approver_access] }
      let(:res) { "stages" }
      let(:ids) { stages1.pluck(:id) }

      it_behaves_like ".approver_id_list"
    end

    describe "for first approver actions" do
      let(:acls) { [approver_access] }
      let(:res) { "actions" }
      let(:ids) { Action.where(:stage_id => stages1.pluck(:id)).pluck(:id).sort }

      it_behaves_like ".approver_id_list"
    end

    describe "for second approver requests" do
      let(:acls) { [approver_access_2] }
      let(:res) { "requests" }
      let(:ids) { requests.pluck(:id).sort }

      it_behaves_like ".approver_id_list"
    end

    describe "for second approver stages" do
      let(:acls) { [approver_access_2] }
      let(:res) { "stages" }
      let(:ids) { [stage2.id] }

      it_behaves_like ".approver_id_list"
    end

    describe "for second approver actions" do
      let(:acls) { [approver_access_2] }
      let(:res) { "actions" }
      let(:ids) { Action.where(:stage_id => stage2.id).pluck(:id) }

      it_behaves_like ".approver_id_list"
    end
  end

  it ".owner_request_ids" do
    ManageIQ::API::Common::Request.with_request(:headers => default_headers, :original_url => "localhost/approval") do
      expect(described_class.owner_request_ids.count).to equal(2)
    end
  end

  it ".owner_acls" do
    expect(described_class.owner_acls('workflows', 'read').count).to equal(1)
    expect(described_class.owner_acls('actions', 'read').count).to equal(0)
  end

  it "rbac is enabled by default" do
    expect(described_class.enabled?).to be_truthy
  end

  it "rbac is disabled by env variable" do
    with_modified_env :BYPASS_RBAC => "1" do
      expect(described_class.enabled?).to be_falsey
    end
  end
end
