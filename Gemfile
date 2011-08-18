source "http://rubygems.org"

# Specify your gem's dependencies in ey_services_api.gemspec
gemspec

group :test, :development do
  gem 'ey_sso', :git => "git@github.com:engineyard/ey_sso.git"

  # gem 'tresfiestas', :git => "git@github.com:engineyard/tresfiestas.git"
  gem 'tresfiestas', :path => "../tresfiestas"

  #TODO: this should just be a dep of tresfiestas
  gem 'lisonja', :path => "../lisonja"
  #TODO: this should just be a dep of lisonja
  gem 'ey_services_api', :path => "../ey_services_api"

  gem 'sinatra'
end
