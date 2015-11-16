WebMock fixtures
================
Library for managing [WebMock][] fixtures.

[WebMock]: https://github.com/bblimke/webmock

[Documentation](http://www.rubydoc.info/github/underdogio/webmock-fixtures).

## Installation
`gem install webmock-fixtures`

or with Bundler

`gem "webmock-fixtures"`

## Getting Started
WebMock fixtures provides a way to pre-define all of your fixtures ahead of time and start them easily during tests.

```ruby
require "rspec"
require "webmock/fixtures"
require "webmock/rspec"

# Register our fixture for www.example.org
WebMock::Fixtures::Manager.register_fixture(
  :get_example, :get, %r{www.example.org}, :body => "Hello World")

RSpec.describe do
  describe "a web request to www.example.org" do
    # Start the registered fixtures
    # DEV: `WebMock` will auto-reset after each test:
    #   https://github.com/bblimke/webmock/blob/v1.22.3/lib/webmock/rspec.rb#L23-L31
    let!(:manager) { WebMock::Fixtures::Manager.run([:get_example]) }

    it "should respond with the fixture body" do
      # Assert that an HTTP request gets the expected response
      response = Net::HTTP.get("www.example.org", "/")
      expect(response).to(eq("Hello World"))

      # Assert that our stub was called
      # DEV: `stub` is the created `WebMock::RequestStub` for the started fixture
      stub = manager[:get_example]
      expect(stub).to(have_been_requested.once)
    end
  end
end
```

As well, by subclassing `WebMock::Fixtures::Manager` you can easily separate and organize your test fixtures. For example:

```ruby
# Manager to store fixtures associated with Google
class GoogleManager < WebMock::Fixtures::Manager
  # Define fixtures in class definition
  @fixtures = {
    :get_homepage => {
      :verb => :get,
      :pattern => %r{www.google.com},
      :response => {
        :body => "Google",
      },
    },
  }
end

# Manager to store fixtures associated with Elasticsearch
class ElasticsearchManager < WebMock::Fixtures::Manager
end
ElasticsearchManager.register_fixture_file(
  :search_people, :get, %r{localhost:9002/people/person/_search}, "/path/to/file.raw")

google_manager = GoogleManager.run([:get_homepage])
elasticsearch_manager = ElasticsearchManager.run([:search_people])
```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality.

## License
Copyright (c) 2015 Underdog.io

Licensed under the MIT license.
