local NpTrafficSplitterHandler = {
    VERSION = "1.0.0",
    PRIORITY = 1000,
}

local UPSTREAM_FORCE_HEADER_NAME = "X-NP-Upstream"

local function split(s, delimiter)
    local delimiter = delimiter or '%s'
    local t = {}
    local i = 1
    for str in string.gmatch(s, '([^'..delimiter..']+)') do
        t[i] = str
        i = i + 1
    end
    return t
end

local function force_upstream_by_header(expected_value)
    return kong.request.get_header(UPSTREAM_FORCE_HEADER_NAME) == expected_value
end

local function eat_cookie(cookie)
    local result = ""
    for cookie_attr in string.gmatch(cookie, '([^'.."; "..']+)') do
        if result == "" then
            local key_val = split(cookie_attr, "=")
            if key_val[1] == UPSTREAM_FORCE_HEADER_NAME then
                result = key_val[2]
                break
            end
        end
    end
    return result
end

local function force_upstream_by_cookie(cookies, expected_value)
    local cookie_type = type(cookies)
    local result = ""
    if cookie_type == "string" then
        result = eat_cookie(cookies)
    elseif cookie_type == "table" then
        local cookie_size = #cookies
        for i = 1, cookie_size do
            if result == "" then
                result = eat_cookie(cookies[i])
            end
        end
    end
    return result == expected_value
end

function NpTrafficSplitterHandler:access(conf)
    local upstream_url
    local rand = math.random(100) -- Get a random number between 1 and 100
    -- Choose upstream by force header
    local choose_primary = force_upstream_by_header("false")
    local choose_secondary = force_upstream_by_header("true")
    print("Target ", conf.upstream)
    -- Choose upstream by cookie (only if conf contains use_cookies)
    if not choose_primary and not choose_secondary and conf.use_cookies and conf.use_cookies.enabled and cookies then
        local cookies = kong.request.get_header("Cookie")
        choose_primary = force_upstream_by_cookie(cookies, "0")
        choose_secondary = force_upstream_by_cookie(cookies, "1")
    end

    -- Choose upstream according to random number or force secondary if request header is present
    if choose_secondary or (rand <= conf.traffic_percentage_for_secondary and not choose_primary)  then
        -- Send traffic to the secondary service based on the configured percentage
        kong.service.request.set_scheme(conf.schema)
        if conf.upstream then
            -- For Kong 3.X
            kong.log.debug("Routing to secondary upstream URL: ", conf.upstream)
            local ok, err = kong.service.set_upstream(conf.upstream)
            if not ok then
                kong.log.err("Error going to upstream: ", conf.upstream," -- ",err)
            end
        else
            -- For Kong 2.X+
            kong.log.debug("Routing to secondary target URL: ", conf.domain)
            kong.service.set_target(conf.domain, conf.port)
        end

        -- Add header to response to identify the actual host
        -- kong.response.add_header("X-NP-Routing", "1")
        kong.response.add_header(UPSTREAM_FORCE_HEADER_NAME, "1")

        if conf.preserve_host == true then
            kong.service.request.set_header("Host", kong.request.get_host())
        else
            kong.service.request.set_header("Host", conf.domain)
        end

        -- if conf.disable_np_host ~= true then
        --     kong.service.request.set_header("X-NP-Host", domain)
        -- end
    else
        kong.response.add_header(UPSTREAM_FORCE_HEADER_NAME, "0")
        -- Only for logging in case of default routing
        if conf.upstream then
            -- For Kong 3.X
            kong.log.debug("Routing to primary upstream URL: ", conf.upstream)
        else
            -- For Kong 2.X+
            kong.log.debug("Routing to pimary target URL: ", conf.domain)
        end
    end
end

local function cookie_is_in_jar(cookie)
    local key_val = split(cookie, "=")
    if key_val[1] == UPSTREAM_FORCE_HEADER_NAME then
        return true
    end
    return false
end

local function bake_cookie(cookie_conf)
    local cookie_val = kong.response.get_header(UPSTREAM_FORCE_HEADER_NAME)
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
    return UPSTREAM_FORCE_HEADER_NAME .. "=" .. cookie_val
        .. (cookie.max_age and "; Max-Age=" .. cookie.max_age or "")
        .. (cookie.path and "; Path=" .. cookie.path or "")
        .. (cookie_conf.secure and "; Secure" or "")
        .. (cookie_conf.http_only and "; HttpOnly" or "")
        .. (cookie.same_site and "; SameSite=" .. cookie.same_site or "")
end

function NpTrafficSplitterHandler:header_filter(conf)
    if conf.use_cookies and conf.use_cookies.enabled and cookies then
        local cookie_header = kong.response.get_header("Set-Cookie")
        local cookie_type = type(cookie_header)
        if cookie_type == "string" then
            if not cookie_is_in_jar(cookie_header) then
                cookies = {}
                cookies[1] = cookie_header
                cookies[2] = bake_cookie(conf.use_cookies)
                kong.response.set_header("Set-Cookie", cookies)
            end
        elseif cookie_type == "table" then
            local cookie_header_size = #cookie_header
            for i = 1, cookie_header_size do
                if not upstream_cookie_exists then
                    upstream_cookie_exists = cookie_is_in_jar(cookie_header[i])
                end
            end
            if not upstream_cookie_exists then
                cookie_header[cookie_header_size + 1] = bake_cookie(conf.use_cookies)
                kong.response.set_header("Set-Cookie", cookie_header)
            end
        else
            kong.response.set_header("Set-Cookie", bake_cookie(conf.use_cookies))
        end
    end
end

return NpTrafficSplitterHandler
