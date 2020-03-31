describe WorkflowPolicy do
  include_context "approval_rbac_objects"

  let(:workflows) { create_list(:workflow, 3) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible_flag) }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true) }

  describe 'with admin role' do
    let(:accessible_flag) { true }
    before { allow(access).to receive(:admin_scope?).and_return(true) }

    context 'with class' do
      subject { described_class.new(user, Workflow) }

      it '#create?' do
        expect(subject.create?).to be_truthy
      end

      it '#query?' do
        expect(subject.query?).to be_truthy
      end
    end

    context 'with instance' do
      subject { described_class.new(user, workflows.first) }

      it '#show?' do
        expect(subject.show?).to be_truthy
      end

      it '#update?' do
        expect(subject.update?).to be_truthy
      end

      it '#destroy?' do
        expect(subject.destroy?).to be_truthy
      end
    end
  end

  describe 'with approver role' do
    let(:accessible_flag) { false }

    context 'with class' do
      subject { described_class.new(user, Workflow) }

      it '#create?' do
        expect(subject.create?).to be_falsey
      end

      it '#query?' do
        expect(subject.query?).to be_falsey
      end
    end

    context 'with instance' do
      subject { described_class.new(user, workflows.first) }

      it '#show?' do
        expect(subject.show?).to be_falsey
      end

      it '#update?' do
        expect(subject.update?).to be_falsey
      end

      it '#destroy?' do
        expect(subject.destroy?).to be_falsey
      end
    end
  end

  describe 'with requester role' do
    subject { described_class.new(user, workflows.first) }

    context 'when permission_check is true' do
      let(:accessible_flag) { true }

      it '#show?' do
        expect(subject.show?).to be_truthy
      end

      it '#query?' do
        expect(described_class.new(user, Workflow).query?).to be_truthy
      end
    end

    context 'when permission_check is false' do
      let(:accessible_flag) { false }

      it '#create?' do
        expect(described_class.new(user, Workflow).create?).to be_falsey
      end

      it '#update?' do
        expect(subject.update?).to be_falsey
      end

      it '#destroy?' do
        expect(subject.destroy?).to be_falsey
      end
    end
  end
end
