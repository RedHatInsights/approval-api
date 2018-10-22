describe UsersConstraint do
  describe '#matches?' do
    it "returns true when the version matches the 'Accept' header" do
      request = double(host: 'api.localhost',
                       headers: { 'Accept' => 'application/approval.localhost.v1' })
      expect(described_class.matches?(request)).to be_truthy
    end

    it "returns the default version when 'default' option is specified" do
      request = double(host: 'api.localhost')
      expect(described_class.matches?(request)).to be_truthy
    end
  end
end
