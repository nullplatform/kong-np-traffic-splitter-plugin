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
        set_upstream = function() end,
      },
      request = {
        get_host = function() return "example.com" end,
        get_header = function() return "" end,
      },
      response = {
        add_header = function() end,
      },
      log = {
        debug = function() end,
        err = function() end,
      }
    }
    _G.ngx = {
      var = {}
    }
    NpTrafficSplitterHandler = require "handler"
  end)

  before_each(function()
    stub(kong.service.request, "set_scheme")
    stub(kong.service, "set_target")
    stub(kong.service, "set_upstream")
    stub(kong.service.request, "set_header")
    stub(kong.response, "add_header")
    stub(kong.log, "debug")
  end)

  after_each(function()
    kong.service.request.set_scheme:revert()
    kong.service.set_target:revert()
    kong.service.set_upstream:revert()
    kong.service.request.set_header:revert()
    kong.response.add_header:revert()

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
    
    it("routes to secondary using upstream when random is within threshold", function()
      math.random = function() return 50 end  -- Mocking math.random
      local conf = {
        traffic_percentage_for_secondary = 60,
        domain = "example.org",
        upstream = "test",
        schema = "https",
        port = 443,
        preserve_host = true,
      }

      NpTrafficSplitterHandler:access(conf)

      assert.stub(kong.service.set_target).was_not_called_with("example.org", 443)
      assert.stub(kong.service.set_upstream).was_called_with("test")
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

    it("set cookie if no cookie send and use_cookies enabled", function()
      math.random = function() return 10 end
      local conf = {
        traffic_percentage_for_secondary = 20,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = false,
        disable_np_host = false,
        use_cookies = {
          enabled = true
        }
      }
      NpTrafficSplitterHandler:access(conf)
      assert.stub(kong.response.add_header).was.called(2)
      local set_cookie_call = kong.response.add_header.calls[1]
      assert.are.equal("Set-Cookie", set_cookie_call.vals[1])
      assert.are.equal("NPUpstreamSelector=10", set_cookie_call.vals[2])
    end)

    it("do not set cookie if cookie send and use_cookies enabled", function()
      math.random = function() return 10 end
      local conf = {
        traffic_percentage_for_secondary = 20,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = false,
        disable_np_host = false,
        use_cookies = {
          enabled = true
        }
      }
      ngx.var["cookie_NPUpstreamSelector"] = "10"
      NpTrafficSplitterHandler:access(conf)
      assert.stub(kong.response.add_header).was.called(1)
    end)

    it("use cookie if send and use_cookies enabled to choose upstream", function()
      math.random = function() return 10 end
      local conf = {
        traffic_percentage_for_secondary = 20,
        domain = "example.org",
        schema = "https",
        port = 443,
        preserve_host = true,
        disable_np_host = false,
        use_cookies = {
          enabled = true
        }
      }
      ngx.var["cookie_NPUpstreamSelector"] = "7"
      NpTrafficSplitterHandler:access(conf)
      assert.stub(kong.service.set_target).was_called_with("example.org", 443)
      assert.stub(kong.service.request.set_scheme).was_called_with("https")
      assert.stub(kong.service.request.set_header).was_called_with("X-NP-Host", "example.org")
      assert.stub(kong.service.request.set_header).was_called_with("Host", "example.com")
    end)

  end)
end)
