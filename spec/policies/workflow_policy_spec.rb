describe WorkflowPolicy do
  include_context "approval_rbac_objects"

  let(:workflow) { create(:workflow) }
  subject { described_class.new(user, workflow) }

  shared_examples_for 'all_falsey' do
    it 'returns false from #create?' do
      expect(subject.create?).to be_falsey
    end

    it 'returns false from #update?' do
      expect(subject.update?).to be_falsey
    end

    it 'returns false from #destroy?' do
      expect(subject.destroy?).to be_falsey
    end

    it 'returns false from #link?' do
      expect(subject.update?).to be_falsey
    end

    it 'returns false from #unlink?' do
      expect(subject.destroy?).to be_falsey
    end
  end

  describe 'with admin role' do
    before { admin_access }

    it 'returns true from #create?' do
      expect(subject.create?).to be_truthy
    end

    it 'returns true from #show?' do
      expect(subject.show?).to be_truthy
    end

    it 'returns true from #update?' do
      expect(subject.update?).to be_truthy
    end

    it 'returns true from #destroy?' do
      expect(subject.destroy?).to be_truthy
    end

    it 'returns true from #link?' do
      expect(subject.update?).to be_truthy
    end

    it 'returns true from #unlink?' do
      expect(subject.destroy?).to be_truthy
    end

    it 'returns all user capabilities from #user_capabilities' do
      result = { "create"=>true,
                 "destroy"=>true,
                 "link"=>true,
                 "show"=>true,
                 "unlink"=>true,
                 "update"=>true }

      expect(subject.user_capabilities).to eq(result)
    end
  end

  describe 'with approver role' do
    before { approver_access }

    it_behaves_like 'all_falsey'
    
    it 'returns false from #show?' do
      expect(subject.show?).to be_falsey
    end

    it 'returns true from #user_capabilities' do
      result = { "create"=>false,
                 "destroy"=>false,
                 "link"=>false,
                 "show"=>false,
                 "unlink"=>false,
                 "update"=>false }

      expect(subject.user_capabilities).to eq(result)
    end
  end

  describe 'with user role' do
    before { user_access }

    it_behaves_like 'all_falsey'
    
    it 'returns true from #show?' do
      expect(subject.show?).to be_truthy
    end

    it 'returns all user capabilities from #user_capabilities' do
      result = { "create"=>false,
                 "destroy"=>false,
                 "link"=>false,
                 "show"=>true,
                 "unlink"=>false,
                 "update"=>false }

      expect(subject.user_capabilities).to eq(result)
    end
  end
end
