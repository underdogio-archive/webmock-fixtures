require "webmock/fixtures"
require "webmock/rspec"

describe WebMock::Fixtures::Manager do
  after(:example) do
    # Ensure we remove any added fixtures between tests
    WebMock::Fixtures::Manager.reset!
  end

  before(:example) do
    # Register a single fixture before each test
    WebMock::Fixtures::Manager.register_fixture(:get_example, :get, %r{www.example.org}, :body => "Hello World")
  end

  describe "::reset!" do
    it "should remove any registered fixtures" do
      expect(WebMock::Fixtures::Manager.fixtures[:get_example]).to_not(be_nil)
      WebMock::Fixtures::Manager.reset!
      expect(WebMock::Fixtures::Manager.fixtures).to(eq({}))
    end
  end

  describe "::register_fixture" do
    context "with a subclassed manager" do
      it "should not share registered fixtures" do
        class TestManager < WebMock::Fixtures::Manager
          @fixtures = {
            :get_google => {
              :verb => :get,
              :pattern => %r{www.google.com},
              :response => {
                :body => "Google",
              },
            },
          }
        end

        # Ensure TestManager has the appropriate fixtures
        expect(TestManager.fixtures.keys()).to(eq([:get_google]))
        expect(TestManager.fixtures[:get_google]).to_not(be_nil)

        # Ensure WebMock::Fixtures::Manager has the appropriate fixtures
        expect(WebMock::Fixtures::Manager.fixtures.keys()).to(eq([:get_example]))
        expect(WebMock::Fixtures::Manager.fixtures[:get_google]).to(be_nil)
      end
    end

    it "should properly register the fixture" do
      expected = {
        :pattern => %r{www.example.org},
        :verb => :get,
        :response => {
          :body => "Hello World",
        },
      }
      expect(WebMock::Fixtures::Manager.fixtures[:get_example]).to(eq(expected))
    end

    it "should properly respond to a web request" do
      # Start our fixtures
      manager = WebMock::Fixtures::Manager.run([:get_example])

      # Assert http call responds with our fixture
      response = Net::HTTP.get("www.example.org", "/")
      expect(response).to(eq("Hello World"))

      # Assert our stub was requested
      stub = manager[:get_example]
      expect(stub).to(have_been_requested.once)
    end
  end

  describe "::register_fixture_file" do
    before(:example) do
      fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "get_httpbin_200.raw")
      WebMock::Fixtures::Manager.register_fixture_file(
        :get_httpbin, :get, %r{^http://httpbin\.org/get\?page=1$}, fixture_path)
    end

    it "should properly register a fixture" do
      fixture = WebMock::Fixtures::Manager.fixtures[:get_httpbin]
      expect(fixture[:verb]).to(eq(:get))
      expect(fixture[:pattern]).to(eq(%r{^http://httpbin\.org/get\?page=1$}))

      # Assert that we loaded the raw HTTP request from the file as a string
      expect(fixture[:response]).to(be_a(String))
      # Assert we have response headers
      expect(fixture[:response]).to(match(%r{Content-Type: application/json}))
      # Assert we have part of the response body
      expect(fixture[:response]).to(match(%r{"url": "http://httpbin\.org/get\?page=1"}))
    end

    it "should properly respond to a web request" do
      # Start our fixtures
      manager = WebMock::Fixtures::Manager.run([:get_httpbin])

      # Assert http call responds with our fixture
      response = Net::HTTP.get(URI("http://httpbin.org/get?page=1"))
      response = JSON.load(response)
      expect(response["url"]).to(eq("http://httpbin.org/get?page=1"))

      # Assert that our stub was requested
      stub = manager[:get_httpbin]
      expect(stub).to(have_been_requested.once)
    end
  end

  describe "::run" do
    context "with an unknown fixture name" do
      it "should raise an error" do
        expect { WebMock::Fixtures::Manager.run([:unknown_fixture]) } .to(raise_error(KeyError))
      end
    end

    context "with multiple instances" do
      before(:example) do
        # Register an additional fixture to use during these tests
        WebMock::Fixtures::Manager.register_fixture(:get_google, :get, %r{www.google.com}, :body => "Google")
      end

      it "should not share started fixtures" do
        google_manager = WebMock::Fixtures::Manager.run([:get_google])
        example_manager = WebMock::Fixtures::Manager.run([:get_example])

        expect(google_manager.started_fixtures.keys()).to(eq([:get_google]))
        expect(example_manager.started_fixtures.keys()).to(eq([:get_example]))
      end
    end

    it "should return a manager" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      expect(manager).to(be_a(WebMock::Fixtures::Manager))
    end

    it "should start the requested request stub" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      expect(manager.started_fixtures.keys()).to(eq([:get_example]))
      expect(manager.started_fixtures[:get_example]).to(be_a(WebMock::RequestStub))
    end
  end

  describe "::new" do
    it "should not start any fixtures" do
      manager = WebMock::Fixtures::Manager.new()
      expect(manager.started_fixtures).to(eq({}))
    end
  end

  describe "#[]" do
    it "should retreive a started fixture" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      expect(manager[:get_example]).to(be_a(WebMock::RequestStub))
    end

    it "should raise an error with an unknown fixture" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      expect { manager[:unknown_example] }.to(raise_error(KeyError))
    end
  end

  describe "#[]=" do
    it "should assign over a known fixture" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      manager[:get_example] = "Test"
      expect(manager[:get_example]).to(eq("Test"))
    end

    it "should assign a new fixture" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      manager[:unknown_example] = "Test"
      expect(manager[:unknown_example]).to(eq("Test"))
    end

    it "should not effect existing fixtures" do
      manager = WebMock::Fixtures::Manager.run([:get_example])
      manager[:unknown_example] = "Test"
      expect(manager[:get_example]).to(be_a(WebMock::RequestStub))
    end
  end
end
