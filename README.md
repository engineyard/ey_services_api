# EY Services API

This gem provides basic ability to interact with Engine Yard as a service partner (e.g. [http://www.engineyard.com/partners/platform-services](http://www.engineyard.com/partners/platform-services)).

All operations happen on the connection.  First it must be setup.  For example:

    EY::ServicesAPI.setup(:auth_id => "...", :auth_key => "...")

Then you can do things like register a new service.  For example:

    EY::ServicesAPI.connection.register_service(
      "http://services.engineyard.com/api/1/partners/1/services", {
        :name => "My Service", 
        :description => "my service does things", 
        :service_accounts_url => "http://my-service.example.com/api/1/customers/fancy",
        :home_url => "http://my-service.example.com/",
        :vars => ["MY_SERVICE_API_KEY"] })

# Using this gem in your project

This codebase really contains 2 gems:

 * ey_services_api is the Gem for communicating with services.engineyard.com. Include this in your Gemfile.
 * ey_services_fake is a Gem for helping you to write tests with a working "Fake" in place of talking directly to services.engineyard.com.  Include this in your Gemfile inside the "test" group.

For examples of using the gem in a sinatra app, and in tests see: https://github.com/engineyard/chronatog


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