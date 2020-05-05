describe ApplicationPolicy do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"]) }
  let(:subject) { described_class.new(user_context, double) }

  it "returns false from #index?" do
    expect(subject.index?).to be_falsey
  end

  it "returns false from #show?" do
    expect(subject.show?).to be_falsey
  end

  it "returns false from #create?" do
    expect(subject.create?).to be_falsey
  end

  it "returns false from #new?" do
    expect(subject.new?).to be_falsey
  end

  it "returns false from #update?" do
    expect(subject.update?).to be_falsey
  end

  it "returns false from #edit?" do
    expect(subject.edit?).to be_falsey
  end

  it "returns false from #destroy?" do
    expect(subject.destroy?).to be_falsey
  end

  it "returns all user capabilities from  #user_capabilities" do
    result = {'edit'    => false,
              'update'  => false,
              'create'  => false,
              'index'   => false,
              'destroy' => false,
              'show'    => false,
              'new'     => false }
    expect(subject.user_capabilities).to include(result)
  end
end
