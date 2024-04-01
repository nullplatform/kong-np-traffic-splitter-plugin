require "busted.runner"()

describe("NpTrafficSplitterHandler", function()
  local NpTrafficSplitterHandler

  setup(function()
    _G.kong = {
      service = {
        request = {
          set_scheme = function() end,
          set_header = function() end,
        },
        set_target = function() end,
      },
      request = {
        get_host = function() return "example.com" end,
      },
      log = {
        debug = function() end,
      },
    }
    NpTrafficSplitterHandler = require "handler"
  end)

  before_each(function()
    stub(kong.service.request, "set_scheme")
    stub(kong.service, "set_target")
    stub(kong.service.request, "set_header")
    stub(kong.log, "debug")
  end)

  after_each(function()
    kong.service.request.set_scheme:revert()
    kong.service.set_target:revert()
    kong.service.request.set_header:revert()
    kong.log.debug:revert()
  end)
  teardown(function()
    _G.kong = nil
  end)

  describe("access", function()
    it("routes to secondary when random is within threshold", function()
      math.random = function() return 50 end  -- Mocking math.random
      local conf = {
        traffic_percentage_for_secondary = 60,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = true,
        disable_np_host = false,
      }

      NpTrafficSplitterHandler:access(conf)

      assert.stub(kong.service.set_target).was_called_with("example.org", 443)
      assert.stub(kong.service.request.set_scheme).was_called_with("https")
      assert.stub(kong.service.request.set_header).was_called_with("X-NP-Host", "example.org")
      assert.stub(kong.service.request.set_header).was_called_with("Host", "example.com")
    end)

    it("does not route to secondary when random is above threshold", function()
      math.random = function() return 70 end  -- Mocking math.random
      local conf = {
        traffic_percentage_for_secondary = 60,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = true,
        disable_np_host = false,
      }
    
      NpTrafficSplitterHandler:access(conf)
    
      assert.stub(kong.service.set_target).was_not_called()
    end)

    it("does not set X-NP-Host header when disable_np_host is true", function()
      math.random = function() return 10 end
      local conf = {
        traffic_percentage_for_secondary = 20,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = true,
        disable_np_host = true,
      }
    
      NpTrafficSplitterHandler:access(conf)
    
      assert.stub(kong.service.request.set_header).was_not_called_with("X-NP-Host", "example.org")
    end)

    it("does not preserve host when preserve_host is false", function()
      math.random = function() return 10 end
      local conf = {
        traffic_percentage_for_secondary = 20,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = false,
        disable_np_host = false,
      }
    
      NpTrafficSplitterHandler:access(conf)
    
      assert.stub(kong.service.request.set_header).was_not_called_with("Host", "example.com")
    end)
  end)
end)