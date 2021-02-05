RSpec.describe GetRemoteTags, :type => :request do
  around do |example|
    Insights::API::Common::Request.with_request(default_request_hash) { example.call }
  end

  let(:object_id) { '123' }
  let(:options) { {:object_type => object_type, :app_name => app_name, :object_id => object_id} }
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
      :CATALOG_INVENTORY_URL => 'http://localhost',
      :CATALOG_URL           => 'http://localhost',
      :SOURCES_URL           => 'http://localhost'
    }
  end

  subject { described_class.new(options) }

  describe 'get tags' do
    it 'successfully fetches tags' do
      stub_request(:get, url).to_return(:status => http_status, :body => {:data => remote_tags}.to_json, :headers => default_headers)

      with_modified_env test_env do
        expect(subject.process.tags).to match([tag1_string, tag2_string])
      end
    end

    context 'with invalid object_type' do
      let(:object_type) { 'InvalidObjectType' }

      it 'raises user error' do
        with_modified_env test_env do
          expect { subject.process }.to raise_error(Exceptions::UserError)
        end
      end
    end

    it 'raises tagging error' do
      stub_request(:get, url).to_raise(Faraday::BadRequestError)

      with_modified_env test_env do
        expect { subject.process }.to raise_error(Exceptions::TaggingError)
      end
    end

    it 'raises network error' do
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed)

      with_modified_env test_env do
        expect { subject.process }.to raise_error(Exceptions::NetworkError)
      end
    end

    it 'raises timeout error' do
      stub_request(:get, url).to_raise(Faraday::TimeoutError)

      with_modified_env test_env do
        expect { subject.process }.to raise_error(Exceptions::TimedOutError)
      end
    end

    it 'raises authentication error' do
      stub_request(:get, url).to_raise(Faraday::UnauthorizedError)

      with_modified_env test_env do
        expect { subject.process }.to raise_error(Exceptions::NotAuthorizedError)
      end
    end
  end
end
