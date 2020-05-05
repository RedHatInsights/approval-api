RSpec.describe WorkflowGetService do
  around do |example|
    Insights::API::Common::Request.with_request(RequestSpecHelper.default_request_hash) { example.call }
  end

  let(:workflow) { create(:workflow, :group_refs => [{'name' => 'group1', 'uuid' => 'uuid'}]) }

  describe '#get' do
    context 'group exists' do
      before { allow(Group).to receive(:find).and_return(group) }

      context 'with approver role' do
        let(:group) { instance_double(Group, :name => 'newname', :uuid =>'uuid', :can_approve? => true) }

        it 'updates group name with latest value' do
          found = described_class.new(workflow.id).get

          expect(found.group_refs).to eq([{'name' => 'newname', 'uuid' => 'uuid'}])
          expect(Workflow.find(workflow.id).group_refs).to eq([{'name' => 'newname', 'uuid' => 'uuid'}])
        end
      end

      context 'without approver role' do
        let(:group) { instance_double(Group, :name => 'newname', :can_approve? => false) }

        it 'appends (No approver permission) to group name' do
          found = described_class.new(workflow.id).get

          expect(found.group_refs).to eq([{'name' => 'newname(No approver permission)', 'uuid' => 'uuid'}])
          expect(Workflow.find(workflow.id).group_refs).to eq([{'name' => 'newname(No approver permission)', 'uuid' => 'uuid'}])
        end
      end
    end

    context 'group does not exist' do
      before { allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi, {}).and_yield(group_api) }
      let(:group_api) do
        instance_double(RBACApiClient::GroupApi).tap do |api|
          allow(api).to receive(:get_group).and_raise(RBACApiClient::ApiError.new(:code => 404))
        end
      end

      it 'appends (Group does not exist) to name' do
        found = described_class.new(workflow.id).get

        expect(found.group_refs).to eq([{'name' => 'group1(Group does not exist)', 'uuid' => 'uuid'}])
        expect(Workflow.find(workflow.id).group_refs).to eq([{'name' => 'group1(Group does not exist)', 'uuid' => 'uuid'}])
      end
    end

    context 'rbac error' do
      before { allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi, {}).and_yield(group_api) }

      let(:group_api) do
        instance_double(RBACApiClient::GroupApi).tap do |api|
          allow(api).to receive(:get_group).and_raise(RBACApiClient::ApiError.new(:code => 500))
        end
      end

      it 'keeps the old name' do
        found = described_class.new(workflow.id).get

        expect(found.group_refs).to eq([{'name' => 'group1', 'uuid' => 'uuid'}])
        expect(Workflow.find(workflow.id).group_refs).to eq([{'name' => 'group1', 'uuid' => 'uuid'}])
      end
    end
  end
end
