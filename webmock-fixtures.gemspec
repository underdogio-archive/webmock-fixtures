$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "webmock/fixtures/version"

Gem::Specification.new do |s|
  # Gem information
  s.name = "webmock-fixtures"
  s.version = WebMock::Fixtures::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Brett Langdon"]
  s.email = ["me@brett.is"]
  s.homepage = "http://github.com/underdogio/webmock-fixtures"
  s.summary = "Manage WebMock fixtures"
  s.description = "Library to help manage WebMock fixtures"
  s.license = "MIT"

  # Dependencies
  s.add_runtime_dependency("webmock", [">= 1.0.0", "< 2.0.0"])
  s.add_development_dependency("rake", [">= 10.0.0", "< 11.0.0"])
  s.add_development_dependency("rspec", [">= 3.3.0", "< 3.4.0"])
  s.add_development_dependency("rubocop", [">= 0.34.0", "< 0.35.0"])

  # Files
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
