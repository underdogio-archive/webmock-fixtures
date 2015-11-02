require "webmock/fixtures"

describe WebMock::Fixtures::Manager do
  describe "constructor" do
    it "should not fail" do
      WebMock::Fixtures::Manager.new()
    end
  end
end
