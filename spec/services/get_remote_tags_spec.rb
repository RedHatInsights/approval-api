RSpec.describe GetRemoteTags, :type => :request do
  around do |example|
    Insights::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:object_id) { '123' }
  let(:options) { {:object_type => object_type, :app_name => app_name, :object_id => object_id} }
  let(:approval_tag) do
    { :tag => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=100" }
  end
  let(:app_name) { 'catalog' }
  let(:object_type) { 'Portfolio' }
  let(:url) { "http://localhost/api/catalog/v1.0/portfolios/#{object_id}/tags?limit=1000" }
  let(:http_status) { [200, 'Ok'] }
  let(:tag1_string) { '/approval/workflows=1' }
  let(:tag2_string) { '/approval/workflows=2' }

  let(:remote_tags) do
    [{:tag => tag1_string},
     {:tag => tag2_string}]
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
        .to_return(:status => http_status, :body => {:data => remote_tags}.to_json, :headers => default_headers)
    end

    it 'successfully fetches tags' do
      with_modified_env test_env do
        expect(subject.process.tags).to match([tag1_string, tag2_string])
      end
    end
  end

  context 'not found' do
    let(:http_status) { [404, 'Not found'] }
    before do
      stub_request(:get, url)
        .to_return(:status => http_status, :body => {:a => 1}.to_json, :headers => default_headers)
    end

    it 'raises error' do
      with_modified_env test_env do
        expect { subject.process }.to raise_error(RuntimeError, /Not found/)
      end
    end
  end
end
