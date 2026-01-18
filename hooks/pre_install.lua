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
    if not jdks or #jdks == 0 then
        error("No JDK found for " .. ctx.version .. " on " .. RUNTIME.osType .. "/" .. RUNTIME.archType .. ". Please check available versions with 'vfox search java'")
    end
    
    -- Filter JDKs based on JavaFX requirement
    local filtered_jdks = {}
    for _, jdk in ipairs(jdks) do
        local jdk_has_fx = jdk.javafx_bundled == true
        if distribution_version.javafx_bundled == jdk_has_fx then
            table.insert(filtered_jdks, jdk)
        end
    end
    
    if #filtered_jdks == 0 then
        local fx_msg = distribution_version.javafx_bundled and " with JavaFX" or " without JavaFX"
        error("No JDK found for " .. ctx.version .. fx_msg .. " on " .. RUNTIME.osType .. "/" .. RUNTIME.archType .. ". Please check available versions with 'vfox search java'")
    end
    
    local jdk = filtered_jdks[1]
    local info = json.decode(httpGet(jdk.links.pkg_info_uri, "Failed to fetch jdk info")).result[1]
    -- TODO: checksum
    -- local checksum = info.checksum
    -- if checksum == "" and info.checksum_uri ~= "" then
    --     checksum = httpGet(info.checksum_uri, "Failed to fetch checksum")
    -- end
    
    -- Build final version string with fx suffix if needed
    local fx_suffix = ""
    if jdk.javafx_bundled == true then
        fx_suffix = "-fx"
    end
    local finalV = distribution_version.distribution.short_name == "open" and jdk.java_version .. fx_suffix or jdk.java_version .. fx_suffix .. "-" .. distribution_version.distribution.short_name
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
