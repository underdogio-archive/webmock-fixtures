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
