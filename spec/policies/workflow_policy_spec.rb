describe WorkflowPolicy do
  include_context "approval_rbac_objects"

  let(:workflows) { create_list(:workflow, 3) }
  let(:user) { instance_double(UserContext) }
  let(:subject) { described_class.new(user, Workflow) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
    allow(rs_class).to receive(:paginate).and_return(acls)
  end

  describe 'with admin role' do
    let(:acls) { admin_acls }

    it '#create?' do
      expect(subject.create?).to be_truthy
    end

    it '#show?' do
      expect(subject.show?).to be_truthy
    end

    it '#update?' do
      expect(subject.update?).to be_truthy
    end

    it '#destroy?' do
      expect(subject.destroy?).to be_truthy
    end

    it '#query?' do
      expect(subject.query?).to be_truthy
    end
  end

  describe 'with approver role' do
    let(:acls) { approver_acls }

    it '#create?' do
      expect(subject.create?).to be_falsey
    end

    it '#show?' do
      expect(subject.show?).to be_falsey
    end

    it '#update?' do
      expect(subject.update?).to be_falsey
    end

    it '#destroy?' do
      expect(subject.destroy?).to be_falsey
    end

    it '#query?' do
      expect(subject.query?).to be_falsey
    end
  end

  describe 'with requester role' do
    let(:acls) { requester_acls }

    it '#create?' do
      expect(subject.create?).to be_falsey
    end

    it '#show?' do
      expect(subject.show?).to be_falsey
    end

    it '#update?' do
      expect(subject.update?).to be_falsey
    end

    it '#destroy?' do
      expect(subject.destroy?).to be_falsey
    end

    it '#query?' do
      expect(subject.query?).to be_falsey
    end
  end
end
