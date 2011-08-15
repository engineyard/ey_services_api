source "http://rubygems.org"

# Specify your gem's dependencies in ey_services_api.gemspec
gemspec

group :test, :development do
  gem 'tresfiestas', :path => "../../"
  # 
  # #Note: would be better if we required lisonja expliclity, which required this... but not supported by gemspecs
  # #all will be sane when we break into separate projects "I promise"
  gem 'lisonja', :path => "../../spike/lisonja"

  gem 'ruby-debug-base19'
  gem 'ruby-debug19'
  
  gem 'sinatra'
end
