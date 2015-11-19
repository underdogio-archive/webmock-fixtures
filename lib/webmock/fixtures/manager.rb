module WebMock
  # WebMock fixture helper
  module Fixtures
    # Class used to manage WebMock fixtures
    class Manager
      # Available fixtures which have been loaded
      @fixtures = {}

      # Fetch the started `WebMock::RequestStub`s that belong to this manager
      # @return [Hash] a Hash of fixture names mapped to their started `WebMock::RequestStub`
      attr_reader :started_fixtures

      # Constructor for Manager
      def initialize
        # We will use `@started_fixtures` to store our started fixtures
        @started_fixtures = {}
      end

      # Fetch the `WebMock::RequestStub` for any started fixtures
      # @param fixture_name [Symbol] the symbol name of the fixture
      # @return [WebMock::RequestStub] the started fixture stub
      # @raise [KeyError] if the fixture requested has not been started
      def [](fixture_name)
        # DEV: `fetch` wil raise `KeyError` if `fixture_name` does not exist
        return @started_fixtures.fetch(fixture_name)
      end

      # Store an instance of `WebMock::RequestStub` for a given fixture
      # @param fixture_name [Symbol] the symbol name of the fixture started
      # @param stub [WebMock::RequestStub] the stub that was started for the fixture
      def []=(fixture_name, stub)
        @started_fixtures[fixture_name] = stub
      end

      # Ensure every subclass of `Manager` sets `@fixtures` to `{}` (by default it will be `nil`)
      # @classmethod
      # @param subclass [Class] the class instance which is subclassing `Manager`
      def self.inherited(subclass)
        subclass.instance_variable_set(:@fixtures, {})
      end

      # Preload a web fixture which can then be started via `Manager.run`
      # @classmethod
      # @param name [Symbol] the name to register the fixture as
      # @param verb [Symbol] symbol method to mock (e.g. `:get`, `:post`)
      # @param pattern [Regexp|String] URI pattern to match for this mock
      # @param response [String|File|Lambda|Hash] the response, this is the same as what would be supplied
      #   to `WebMock::RequestStub#to_return` please see https://github.com/bblimke/webmock for examples
      # @param &block [Proc] a block to use for handling the response.
      # @return [nil]
      def self.register_fixture(name, verb, pattern, response=nil, &block)
        if block_given? && response.nil?
          response = block
        elsif !block_given? && response.nil?
          fail(ArgumentError, "Expected either \"response\" parameter or a block, received neither")
        end
        @fixtures[name] = {
          :pattern => pattern,
          :verb => verb,
          :response => response,
        }
      end

      # Retrieve a hash of registered fixtures available to this Manager
      # @classmethod
      # @return [Hash] a hash mapping the registered name to a hash of properties
      #
      #   e.g. `{ :get_example => { :pattern => %r{example.org}, :verb => :get, :response => "Hello World" } }`
      def self.fixtures
        return @fixtures
      end

      # Reset this manager by removing all previously registered fixtures
      # @classmethod
      # @return [nil]
      def self.reset!
        @fixtures = {}
      end

      # Preload a web fixture from a file which can then be started via `Manager.run`
      # @classmethod
      # @param name [Symbol] the name to register the fixture as
      # @param verb [Symbol] symbol method to mock (e.g. `:get`, `:post`)
      # @param pattern [Regexp|String] URI pattern to match for this mock
      # @param file_name [String] the name of the file to load the fixture response from
      # @return [nil]
      def self.register_fixture_file(name, verb, pattern, file_name)
        # Read the contents from the file and use as the response
        # https://github.com/bblimke/webmock/tree/v1.22.1#replaying-raw-responses-recorded-with-curl--is
        register_fixture(name, verb, pattern, File.new(file_name).read)
      end

      # Register an instance method as a fixture handler
      # @classmethod
      # @param name [Symbol] the name of the instance method, this is also the name the fixture will be registered as
      # @param verb [Symbol] symbol method to mock (e.g. `:get`, `:post`)
      # @param pattern [Regexp|String] URI pattern to match for this mock
      # @return [nil]
      def self.register_fixture_method(name, verb, pattern)
        # DEV: `method` will be an `UnboundMethod` which we can bind later when starting
        method = instance_method(name)
        register_fixture(name, verb, pattern, method)
      end

      # Start the named preloaded web fixtures
      # @classmethod
      # @param fixture_names [Array] the symbol names of fixtures to load and start
      # @return [Manager] an instance of Manager which has properties set for each started fixture
      # @raise [KeyError] if the fixture has not been preloaded via `::register_fixture` or `::register_fixture_file`
      def self.run(fixture_names)
        # Create a new instance to store started mocks on
        manager = new()
        fixture_names.each do |fixture_name|
          # Ensure the named fixture exists
          unless @fixtures.key?(fixture_name)
            fail(KeyError, "The fixture \"#{fixture_name}\" was not found. Please make sure to " +
                           "register it with ::register_fixture or ::register_fixture_file")
          end
          fixture_options = @fixtures[fixture_name]

          # Ensure `UnboundMethod`s are bound to our `Manager` instance
          #   and any `Proc`s are called with our `Manager` instance as the last parameter
          if fixture_options[:response].is_a?(UnboundMethod)
            handler = fixture_options[:response].bind(manager)
            fixture_options[:response] = lambda { |*args| handler.call(*args) }
          elsif fixture_options[:response].is_a?(Proc)
            block = fixture_options[:response]
            fixture_options[:response] = lambda { |*args| block.call(*args, manager) }
          end

          # Create the WebMock stub
          stub = WebMock::API.stub_request(fixture_options[:verb], fixture_options[:pattern])
          stub.to_return(fixture_options[:response])

          # Store the started stub on the manager instance
          manager[fixture_name] = stub
        end
        return manager
      end
    end
  end
end
