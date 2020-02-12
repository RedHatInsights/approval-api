describe "Swagger stuff" do
  describe "Routing" do
    include Rails.application.routes.url_helpers

    %w[1.0 1.1].each do |version|
      context "customizable route prefixes for version #{version}" do
        let(:route_path_name) { "api_v#{version.gsub('.','x')}_requests_url" }

        before do
          stub_const("ENV", ENV.to_h.merge("PATH_PREFIX" => random_path, "APP_NAME" => random_path_part))
          Rails.application.reload_routes!
        end

        after(:all) do
          Rails.application.reload_routes!
        end

        it "with a random prefix" do
          expect(ENV["PATH_PREFIX"]).not_to be_nil
          expect(ENV["APP_NAME"]).not_to be_nil
          expect(send(route_path_name, :only_path => true)).to eq("/#{URI.encode(ENV["PATH_PREFIX"])}/#{URI.encode(ENV["APP_NAME"])}/v#{version}/requests")
        end

        it "with extra slashes" do
          ENV["PATH_PREFIX"] = "//example/path/prefix/"
          ENV["APP_NAME"] = "/appname/"
          Rails.application.reload_routes!

          expect(send(route_path_name, :only_path => true)).to eq("/example/path/prefix/appname/v#{version}/requests")
        end

        it "doesn't use the APP_NAME when PATH_PREFIX is empty" do
          ENV["PATH_PREFIX"] = ""
          Rails.application.reload_routes!

          expect(ENV["APP_NAME"]).not_to be_nil
          expect(send(route_path_name, :only_path => true)).to eq("/api/v#{version}/requests")
        end
      end
    end

    def words
      @words ||= File.readlines("/usr/share/dict/words").collect(&:strip)
    end

    def random_path_part
      rand(1..5).times.collect { words.sample }.join("_")
    end

    def random_path
      rand(1..10).times.collect { random_path_part }.join("/")
    end
  end
end
