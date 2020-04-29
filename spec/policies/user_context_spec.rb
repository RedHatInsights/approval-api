describe UserContext, [:type => :current_forwardble] do
  include_context "approval_rbac_objects"

  let(:current_request) { Insights::API::Common::Request.new(RequestSpecHelper.default_request_hash) }
  subject do
    described_class.new(current_request, "params")
  end

  describe "#access" do
    let(:access) { instance_double(Insights::API::Common::RBAC::Access) }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(access)
      allow(access).to receive(:process).and_return(access)
    end

    it "fetches a memoized access list from RBAC" do
      expect(Insights::API::Common::RBAC::Access).to receive(:new).once
      expect(access).to receive(:process).once

      subject.access
      subject.access
    end
  end

  describe ".with_user_context" do
    it "uses the given user" do
      expect(Thread.current[:user_context]).to be_nil
      UserContext.with_user_context(subject) do |uc|
        expect(uc).to eq(subject)
        expect(Thread.current[:user_context]).not_to be_nil
      end
      expect(Thread.current[:user_context]).to be_nil
    end
  end

  describe ".current_user_context" do
    it "uses the given user" do
      expect(UserContext.current_user_context).to be_nil
      UserContext.with_user_context(subject) do
        expect(UserContext.current_user_context).not_to be_nil
      end
      expect(UserContext.current_user_context).to be_nil
    end
  end

  describe "#rbac_enabled?" do
    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(true)
    end

    it "fetches a memoized enabled flag from RBAC" do
      expect(Insights::API::Common::RBAC::Access).to receive(:enabled?).once
      expect(subject.rbac_enabled?).to be(true)

      subject.rbac_enabled?
    end
  end

  describe "#group_uuids" do
    before do
      allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
      allow(rs_class).to receive(:paginate).with(api_instance, :list_groups, :scope => 'principal')
        .and_return(group_list)
    end

    let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

    it "returns a memoized group uuid list" do
      expect(rs_class).to receive(:call).once
      subject.group_uuids
      expect(subject.group_uuids).to eq(["123-456"])
    end
  end
end
