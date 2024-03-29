local strings = require("vfox.strings")
local http = require("http")
local json = require("json")

local foojay = require("foojay")
local shortname = require("shortname")
--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version_parts = strings.split(ctx.version, "-")
    local version = version_parts[1]
    local distribution = version_parts[2] or "open"
    if not shortname[distribution] then
        error("Unsupport distribution: " .. distribution)
    end
    local jdks = foojay.fetchtJdkList(shortname[distribution], version)
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
    local finalV = distribution == "open" and jdk.java_version or jdk.java_version .. "-" .. distribution
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
