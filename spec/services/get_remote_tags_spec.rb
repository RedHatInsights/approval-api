RSpec.describe GetRemoteTags do
  around do |example|
    ManageIQ::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:object_id) { '123' }
  let(:options) { {:object_type => object_type, :app_name => app_name, :object_id => object_id} }
  let(:approval_tag) do
    { :namespace => WorkflowLinkService::TAG_NAMESPACE,
      :name      => WorkflowLinkService::TAG_NAME,
      :value     => "100" }
  end
  let(:app_name) { 'catalog' }
  let(:object_type) { 'Portfolio' }
  let(:url) { "http://localhost/api/catalog/v1.0/portfolios/#{object_id}/tags" }
  let(:http_status) { [200, 'Ok'] }
  let(:headers)     do
    { 'Content-Type' => 'application/json' }.merge(default_headers)
  end

  let(:remote_tags) do
    [{:name => 'Charkie', :namespace => 'Gnocchi', :value => 'Hundley'},
     {:name => 'Curious George', :namespace => 'Jumpy Squirrel', :value => 'Compass'}]
  end

  let(:test_env) do
    {
      :TOPOLOGICAL_INVENTORY_URL => 'http://localhost',
      :CATALOG_URL               => 'http://localhost',
      :SOURCES_URL               => 'http://localhost'
    }
  end

  subject { described_class.new(options) }

  context 'get tags' do
    before do
      stub_request(:get, url)
        .to_return(:status => http_status, :body => remote_tags.to_json, :headers => headers)
    end

    it 'successfully fetches tags' do
      with_modified_env test_env do
        expect(subject.process.tags).to match(remote_tags)
      end
    end
  end

  context 'not found' do
    let(:http_status) { [404, 'Not found'] }
    before do
      stub_request(:get, url)
        .to_return(:status => http_status, :body => {:a => 1}.to_json, :headers => headers)
    end

    it 'raises error' do
      with_modified_env test_env do
        expect { subject.process }.to raise_error(RuntimeError, /Not found/)
      end
    end
  end
end
