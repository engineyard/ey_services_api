# EY Services API

This gem provides basic ability to interact with Engine Yard services. (http://services.engineyard.com/)

All operations happen on the connection.  First it must be setup.  For example:

```ruby
EY::ServicesAPI.setup(:auth_id => "...", :auth_key => "...")
```

Then you can do things like register a new service.  For example:

```ruby
EY::ServicesAPI.connection.register_service(
  "http://services.engineyard.com/api/1/partners/1/services", {
    :name => "My Service", 
    :description => "my service does things", 
    :service_accounts_url => "http://my-service.example.com/api/1/customers/fancy",
    :home_url => "http://my-service.example.com/",
    :vars => ["MY_SERVICE_API_KEY"] })
```

## To run the tests

To run specs mocked:

 * rvm use 1.8.7
 * bundle
 * bundle exec rake

To run against tresfiestas codebase: (internal only)

 * rvm use 1.9.2
 * BUNDLE_GEMFILE=EYIntegratedGemfile bundle
 * BUNDLE_GEMFILE=EYIntegratedGemfile bundle exec rake

## Releasing

$ rvm use 1.8.7
$ gem install gem-release
$ gem bump
$ gem release
$ git push

This should bump the versions of both ey_services_api and ey_services_fake. Push both to rubygems, and then push your version bump commits to github.

Using 1.8.7 to release is the simplest way to avoid syck/psych yaml incompatibilities gemspec bugs.