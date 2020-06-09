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

  let(:test_env) do
    {
      :TOPOLOGICAL_INVENTORY_URL => 'http://localhost',
      :CATALOG_URL               => 'http://localhost',
      :SOURCES_URL               => 'http://localhost'
    }
  end

  subject { described_class.new(options) }

  shared_examples_for '#test_all' do
    it 'deletes a remote tag' do
      stub_request(:post, url).to_return(status: 200, body: approval_tags.to_json, headers: headers)

      with_modified_env test_env do
        subject.process(approval_tags)
      end
    end

    it 'raises an error if env is missing' do
      expect { subject.process(approval_tags) }.to raise_error(RuntimeError, env_not_set)
    end

    it "raises tagging error" do
      stub_request(:post, url).to_raise(Faraday::BadRequestError)

      with_modified_env test_env do
        expect { subject.process(approval_tags) }.to raise_error(Exceptions::TaggingError)
      end
    end

    it "raises network error" do
      stub_request(:post, url).to_raise(Faraday::ConnectionFailed)

      with_modified_env test_env do
        expect { subject.process(approval_tags) }.to raise_error(Exceptions::NetworkError)
      end
    end

    it "raises timeout error" do
      stub_request(:post, url).to_raise(Faraday::TimeoutError)

      with_modified_env test_env do
        expect { subject.process(approval_tags) }.to raise_error(Exceptions::TimedOutError)
      end
    end

    it "raises authentication error" do
      stub_request(:post, url).to_raise(Faraday::UnauthorizedError)

      with_modified_env test_env do
        expect { subject.process(approval_tags) }.to raise_error(Exceptions::NotAuthorizedError)
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
