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
        kong.service.set_target(domain, conf.port)
        kong.log.debug("Routing to secondary upstream URL: ", domain)
        if conf.preserve_host == true then
          kong.service.request.set_header("Host", kong.request.get_host())
        end
        if conf.disable_np_host ~= true then
          kong.service.request.set_header("X-NP-Host", domain)
        end
    end
end

return NpTrafficSplitterHandler