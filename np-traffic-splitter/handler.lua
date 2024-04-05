local NpTrafficSplitterHandler = {
  VERSION = "1.0.0",
  PRIORITY = 1000,
}

function NpTrafficSplitterHandler:access(conf)
    local upstream_url
    local rand = math.random(100) -- Get a random number between 1 and 100
    if rand <= conf.traffic_percentage_for_secondary then
        -- Send traffic to the secondary service based on the configured percentage
        local domain = conf.domain
        kong.service.request.set_scheme(conf.schema)
        if conf.upstream then
          kong.log.debug("Routing to secondary upstream URL: ", conf.upstream, " -- ",domain)
	  local ok, err = kong.service.set_upstream(conf.upstream)
          if not ok then
            kong.log.err("Error going to upstream: ",conf.upstream," -- ",err)
          end
	else
          kong.log.debug("Routing to secondary target URL: ", domain)
          kong.service.set_target(domain, conf.port)
        end
      
        if conf.preserve_host == true then
          kong.service.request.set_header("Host", kong.request.get_host())
        else
          kong.service.request.set_header("Host", domain)
        end
      
        if conf.disable_np_host ~= true then
          kong.service.request.set_header("X-NP-Host", domain)
        end
    end
end

return NpTrafficSplitterHandler
