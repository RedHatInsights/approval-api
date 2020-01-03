RSpec.describe DeleteRemoteTags, :type => :request do
  around do |example|
    Insights::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:object_id) { '123' }
  let(:options) { {:object_type => object_type, :app_name => app_name, :object_id => object_id} }
  let(:approval_tag) do
    { :tag => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=100" }
  end
  let(:approval_tags) { [approval_tag] }
  let(:http_status) { [200, 'Ok'] }
  let(:headers)     do
    { 'Content-Type' => 'application/json' }.merge(default_headers)
  end

  let(:remote_tags) do
    [{:tag => '/Charkie/Gnocchi=Hundley'},
     {:tag => '/Curious George/Jumpy Squirrel=Compass'}]
  end

  let(:test_env) do
    {
      :TOPOLOGICAL_INVENTORY_URL => 'http://localhost',
      :CATALOG_URL               => 'http://localhost',
      :SOURCES_URL               => 'http://localhost'
    }
  end

  subject { described_class.new(options) }

  shared_examples_for '#test_all' do
    before do
      stub_request(:post, url)
        .to_return(:status => http_status, :body => approval_tags.to_json, :headers => headers)
    end

    it 'deletes a remote tag' do
      with_modified_env test_env do
        subject.process(approval_tags)
      end
    end

    it 'raises an error if env is missing' do
      expect { subject.process(approval_tags) }.to raise_error(RuntimeError, env_not_set)
    end

    context "raises error" do
      let(:http_status) { [404, 'Bad Request'] }
      it 'raises an error if the status is not 200' do
        with_modified_env test_env do
          expect { subject.process(approval_tags) }.to raise_error(RuntimeError, /Error posting tags/)
        end
      end
    end

    context "raises authentication error" do
      let(:http_status) { [403, 'Authentication Error'] }
      it 'raises an error if the status is 403' do
        with_modified_env test_env do
          expect { subject.process(approval_tags) }.to raise_error(Exceptions::NotAuthorizedError, /Authentication Error/)
        end
      end
    end
  end

  context 'catalog' do
    let(:app_name) { 'catalog' }
    let(:env_not_set) { /CATALOG_URL is not set/ }

    context 'portfolio' do
      let(:object_type) { 'Portfolio' }
      let(:url)         { "http://localhost/api/catalog/v1.0/portfolios/#{object_id}/untag" }
      it_behaves_like "#test_all"
    end

    context 'portfolio_item' do
      let(:object_type) { 'PortfolioItem' }
      let(:url)         { "http://localhost/api/catalog/v1.0/portfolio_items/#{object_id}/untag" }
      it_behaves_like "#test_all"
    end
  end

  context 'topology' do
    let(:app_name) { 'topology' }
    let(:env_not_set) { /TOPOLOGICAL_INVENTORY_URL is not set/ }

    context 'credentials' do
      let(:object_type) { 'Credential' }
      let(:url)         { "http://localhost/api/topological-inventory/v2.0/credentials/#{object_id}/untag" }
      it_behaves_like "#test_all"
    end

    context 'ServiceInventory' do
      let(:object_type) { 'ServiceInventory' }
      let(:url)         { "http://localhost/api/topological-inventory/v2.0/service_inventories/#{object_id}/untag" }
      it_behaves_like "#test_all"
    end
  end

  context 'sources' do
    let(:app_name) { 'sources' }
    let(:env_not_set) { /SOURCES_URL is not set/ }

    context 'source' do
      let(:object_type) { 'Source' }
      let(:url)         { "http://localhost/api/sources/v1.0/sources/#{object_id}/untag" }
      it_behaves_like "#test_all"
    end
  end
end
