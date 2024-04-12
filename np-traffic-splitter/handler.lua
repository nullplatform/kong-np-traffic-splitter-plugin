local NpTrafficSplitterHandler = {
	  VERSION = "1.0.0",
	  PRIORITY = 1000,
}
local COOKIE_NAME = "NPUpstreamSelector"
local COOKIE_VAR_NAME = "cookie_" .. COOKIE_NAME

local function bake_selector_cookie(cookie_conf, cookie_val)
    local cookie = {}
    if cookie_conf.max_age then
        cookie.max_age = cookie_conf.max_age
    end
    if cookie_conf.path then
        cookie.path = cookie_conf.path
    end
    if cookie_conf.same_site then
        cookie.same_site = cookie_conf.same_site
    end
    return COOKIE_NAME .. "=" .. cookie_val
        .. (cookie.max_age and "; Max-Age=" .. cookie.max_age or "")
        .. (cookie.path and "; Path=" .. cookie.path or "")
        .. (cookie_conf.secure and "; Secure" or "")
        .. (cookie_conf.http_only and "; HttpOnly" or "")
        .. (cookie.same_site and "; SameSite=" .. cookie.same_site or "")
end


function NpTrafficSplitterHandler:access(conf)
    local upstream_url
    local rand
    if conf.use_cookies and conf.use_cookies.enabled then
        if ngx.var[COOKIE_VAR_NAME] == nil then
            rand = math.random(100)

            kong.response.add_header("Set-Cookie", bake_selector_cookie(conf.use_cookies, rand))
        else
            rand = tonumber(ngx.var[COOKIE_VAR_NAME])
            kong.log.debug("Using cookie selector [selector:"..rand.."]")
        end
    end
    if rand == nil then
        rand = math.random(100)
    end
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
