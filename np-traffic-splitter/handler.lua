local NpTrafficSplitterHandler = {
	  VERSION = "1.0.0",
	  PRIORITY = 1000,
}

function NpTrafficSplitterHandler:access(conf)
    local upstream_url
		local rand = math.random(100) -- Get a random number between 1 and 100
		local choose_primary = kong.request.get_header("X-NP-Upstream") == "false"
		local choose_secondary = kong.request.get_header("X-NP-Upstream") == "true"
    -- Choose upstream according to random number or force secondary if request header is present
		if choose_secondary or (rand <= conf.traffic_percentage_for_secondary and not choose_primary)  then
        -- Send traffic to the secondary service based on the configured percentage
        local domain = conf.domain
        kong.service.request.set_scheme(conf.schema)
				if conf.upstream then
						-- For Kong 3.X
	          kong.log.debug("Routing to secondary upstream URL: ", conf.upstream, " -- ",domain)
		  			local ok, err = kong.service.set_upstream(conf.upstream)
	          if not ok then
	            kong.log.err("Error going to upstream: ",conf.upstream," -- ",err)
	          end
				else
						-- For Kong 2.X
	          kong.log.debug("Routing to secondary target URL: ", domain)
	          kong.service.set_target(domain, conf.port)
        end

        -- Add header to response to identify the actual host
				kong.response.add_header("X-NP-Routing", "1")
      
        if conf.preserve_host == true then
          	kong.service.request.set_header("Host", kong.request.get_host())
        else
          	kong.service.request.set_header("Host", domain)
        end
      
        if conf.disable_np_host ~= true then
          	kong.service.request.set_header("X-NP-Host", domain)
        end
		else
				-- Only for logging in case of default routing
				if conf.upstream then
						-- For Kong 3.X
						kong.log.debug("Routing to primary upstream URL: ", conf.upstream, " -- ",domain)
				else
						-- For Kong 2.X
						kong.log.debug("Routing to pimary target URL: ", domain)
				end
    end
end

return NpTrafficSplitterHandler
