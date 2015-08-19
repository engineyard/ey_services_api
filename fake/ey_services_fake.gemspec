# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ey_services_fake/version"

Gem::Specification.new do |s|
  s.name        = "ey_services_fake"
  s.version     = EyServicesFake::VERSION
  s.authors     = ["Jacob Burkhart & Josh Lane"]
  s.email       = ["jacob@engineyard.com"]
  s.homepage    = "https://github.com/engineyard/ey_services_api"
  s.summary     = %q{A fake for use when writting tests against the ey_services_api}
  s.description = %q{A fake for use when writting tests against the ey_services_api}
  s.license = 'MIT'

  s.rubyforge_project = "ey_services_fake"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "sinatra"
  s.add_dependency "cubbyhole", ">= 0.2.0"
  s.add_dependency "request_visualizer"
end
