source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem 'acts_as_tenant'
gem 'jbuilder',           '~> 2.0'
gem 'manageiq-loggers',   '~> 0.2'
gem 'manageiq-messaging', '~> 0.1'
gem 'pg',                 '~> 1.0', :require => false
gem 'prometheus-client',  '~> 0.8.0'
gem 'puma',               '~> 3.0'
gem 'rack-cors',          '>= 0.4.1'
gem 'rails',              '>= 5.2.2.1', '~> 5.2.2'
gem 'rest-client',        '>= 1.8.0'

gem 'kie_client', :git => "https://github.com/ManageIQ/kie-api-client-ruby", :branch => "master"
gem 'manageiq-api-common', :git => 'https://github.com/ManageIQ/manageiq-api-common', :branch => 'master'
gem 'rbac-api-client', :git => 'https://github.com/RedHatInsights/insights-rbac-api-client-ruby.git', :branch => "master"

group :development, :test do
  gem 'climate_control'
  gem 'simplecov'
end

group :test do
  gem 'factory_bot_rails', '~> 4.0'
  gem 'faker'
  gem 'rspec-rails', '~> 3.5'
  gem 'shoulda-matchers', '~> 3.1'
end
