describe RBAC::ACLS do
  let(:subject) { described_class.new }
  let(:permissions) { ['approval:actions:read', 'approval:actions:create'] }
  let(:resource_id) { "10" }

  context "when create acls based on permissions" do
    it "with resource id" do
      acls = subject.create(resource_id, permissions)

      expect(acls.count).to eq(2)
      expect(acls.first.permission).to eq(permissions.first)
      expect(acls.last.permission).to eq(permissions.last)
      expect(acls.last.resource_definitions.count).to eq(1)
      expect(acls.last.resource_definitions.first.attribute_filter.key).to eq("id")
      expect(acls.last.resource_definitions.first.attribute_filter.operation).to eq("equal")
      expect(acls.last.resource_definitions.first.attribute_filter.value).to eq(resource_id)
    end

    it "without resource id" do
      acls = subject.create(nil, permissions)

      expect(acls.count).to eq(2)
      expect(acls.first.permission).to eq(permissions.first)
      expect(acls.last.permission).to eq(permissions.last)
      expect(acls.last.resource_definitions).to eq([])
    end
  end

  context "when remove acls" do
    let(:acls) { subject.create(resource_id, permissions) }
    let(:existing_permissions) { [permissions.first] }
    let(:not_existing_permissions) { ['approval:requests:read'] }
    let(:mix_existing_permissions) { [permissions.last, 'approval:requests:read'] }

    it "with matching permissions" do
      new_acls = subject.remove(acls, resource_id, existing_permissions)

      expect(new_acls.count).to eq(1)
      expect(new_acls.first.permission).to eq(permissions.last)
      expect(new_acls.first.resource_definitions.count).to eq(1)
    end

    it "with non-matching permissions" do
      new_acls = subject.remove(acls, resource_id, not_existing_permissions)

      expect(new_acls.count).to eq(2)
      expect(new_acls.first.permission).to eq(permissions.first)
      expect(new_acls.last.permission).to eq(permissions.last)
      expect(new_acls.first.resource_definitions.count).to eq(1)
    end

    it "with mixed matching permissions" do
      new_acls = subject.remove(acls, resource_id, mix_existing_permissions)

      expect(new_acls.count).to eq(1)
      expect(new_acls.first.permission).to eq(permissions.first)
      expect(new_acls.first.resource_definitions.count).to eq(1)
    end
  end

  context "when add acls" do
    let(:acls) { subject.create(resource_id, permissions) }
    let(:existing_permissions) { [permissions.first] }
    let(:not_existing_permissions) { ['approval:requests:read'] }
    let(:mix_existing_permissions) { [permissions.last, 'approval:requests:read'] }

    it "with matching permissions" do
      new_acls = subject.add(acls, resource_id, existing_permissions)

      expect(new_acls.count).to eq(2)
      expect(new_acls.first.permission).to eq(permissions.first)
      expect(new_acls.first.resource_definitions.count).to eq(1)
    end

    it "with non-matching permissions" do
      new_acls = subject.add(acls, resource_id, not_existing_permissions)

      expect(new_acls.count).to eq(3)
      expect(new_acls.first.permission).to eq('approval:requests:read')
      expect(new_acls.first.resource_definitions.count).to eq(1)
    end

    it "with mix matching permissions" do
      new_acls = subject.add(acls, resource_id, mix_existing_permissions)

      expect(new_acls.count).to eq(3)
      expect(new_acls.first.permission).to eq('approval:requests:read')
      expect(new_acls.last.permission).to eq(permissions.last)
    end
  end

  context "check resource definitions" do
    let(:acls_with_ids) { subject.create(resource_id, permissions) }
    let(:acls_no_ids)   { subject.create(nil, permissions) }

    it "empty?" do
      with_ids = subject.resource_defintions_empty?(acls_with_ids, permissions.first)
      no_ids   = subject.resource_defintions_empty?(acls_no_ids, permissions.first)

      expect(with_ids).to be_falsey
      expect(no_ids).to be_truthy
    end
  end
end
