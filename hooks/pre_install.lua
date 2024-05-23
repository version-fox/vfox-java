local http = require("http")
local json = require("json")

local foojay = require("foojay")
local distribution_version_parser = require("distribution_version")
--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local distribution_version = distribution_version_parser.parse_version(ctx.version)
    if not distribution_version then
        error("Could not extract a valid distribution: " .. ctx.version)
    end
    local jdks = foojay.fetchtJdkList(distribution_version.distribution.name, distribution_version.version)
    if not #jdks then
        return {}
    end
    local jdk = jdks[1]
    local info = json.decode(httpGet(jdk.links.pkg_info_uri, "Failed to fetch jdk info")).result[1]
    -- TODO: checksum
    -- local checksum = info.checksum
    -- if checksum == "" and info.checksum_uri ~= "" then
    --     checksum = httpGet(info.checksum_uri, "Failed to fetch checksum")
    -- end
    local finalV = distribution_version.distribution.short_name == "open" and jdk.java_version or jdk.java_version .. "-" .. distribution_version.distribution.short_name
    return {
        -- [info.checksum_type] = checksum,
        url = info.direct_download_uri,
        version = finalV,
        note = jdk.major_version
    }
end

function httpGet(url, errMsg)
    local resp, err = http.get({
        url = url
    })
    if err ~= nil then
        error(errMsg .. ": " .. err)
    end
    if resp.status_code ~= 200 then
        error(errMsg .. ": status_code =>" .. resp.status_code)
    end
    return resp.body
end
