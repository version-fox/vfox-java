-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local http = require("http")
local json = require("json")

local foojay = require("foojay")
local loongnix = require("loongnix")
local distribution_version_parser = require("distribution_version")
--- @class PreInstallContext
--- @field version string User-input version

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx PreInstallContext
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local distribution_version = distribution_version_parser.parse_version(ctx.version)
    if not distribution_version then
        error("Could not extract a valid distribution: " .. ctx.version)
    end
    if loongnix.supported() or loongnix.is_distribution(distribution_version.distribution.name) then
        return loongnix.pre_install(distribution_version)
    end
    local jdks = foojay.fetchtJdkList(distribution_version.distribution.name, distribution_version.version)
    if not jdks or #jdks == 0 then
        error(
            "No JDK found for "
                .. ctx.version
                .. " on "
                .. RUNTIME.osType
                .. "/"
                .. RUNTIME.archType
                .. ". Please check available versions with 'vfox search java'"
        )
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
        error(
            "No JDK found for "
                .. ctx.version
                .. fx_msg
                .. " on "
                .. RUNTIME.osType
                .. "/"
                .. RUNTIME.archType
                .. ". Please check available versions with 'vfox search java'"
        )
    end

    -- For Oracle GraalVM, latest=available lists the monthly feature releases
    -- (25.4.4.1) before the 25.0 line, which Oracle's own 25/latest download
    -- tracks; a bare major takes the newest 25.0 build instead.
    if distribution_version.distribution.name == "graalvm" and distribution_version.version:match("^%d+$") then
        local releases = {}
        for _, candidate in ipairs(filtered_jdks) do
            if not distribution_version_parser.is_feature_release(candidate.java_version) then
                table.insert(releases, candidate)
            end
        end
        -- A major with feature releases only keeps them.
        if #releases > 0 then
            filtered_jdks = releases
        end
    end

    local jdk = filtered_jdks[1]
    -- Windows lists a version's zip and tar.gz packages in either order;
    -- install the zip where there is one.
    for _, candidate in ipairs(filtered_jdks) do
        if candidate.java_version == jdk.java_version and candidate.archive_type == "zip" then
            jdk = candidate
            break
        end
    end
    if not jdk.links or not jdk.links.pkg_info_uri then
        error("Invalid JDK package info: missing download links for " .. ctx.version)
    end
    local info = json.decode(httpGet(jdk.links.pkg_info_uri, "Failed to fetch jdk info")).result[1]
    -- TODO: checksum
    -- local checksum = info.checksum
    -- if checksum == "" and info.checksum_uri ~= "" then
    --     checksum = httpGet(info.checksum_uri, "Failed to fetch checksum")
    -- end

    -- Build final version string with fx suffix if needed (after distribution name)
    local fx_suffix = ""
    if jdk.javafx_bundled == true then
        fx_suffix = "-fx"
    end

    local finalV
    if distribution_version.distribution.short_name == "open" then
        finalV = jdk.java_version .. fx_suffix
    else
        finalV = jdk.java_version .. "-" .. distribution_version.distribution.short_name .. fx_suffix
    end
    return {
        -- [info.checksum_type] = checksum,
        url = info.direct_download_uri,
        version = finalV,
        note = jdk.major_version,
    }
end

function httpGet(url, errMsg)
    local resp, err = http.get({
        url = url,
    })
    if err ~= nil then
        error(errMsg .. ": " .. err)
    end
    if resp.status_code ~= 200 then
        error(errMsg .. ": status_code =>" .. resp.status_code)
    end
    return resp.body
end
