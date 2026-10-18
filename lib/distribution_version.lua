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

local strings = require("vfox.strings")

local short_name = {
    ["open"] = "openjdk",
    ["lnxabi1"] = "loongnix_abi1",
    ["lnxabi2"] = "loongnix_abi2",
    ["bsg"] = "bisheng",
    ["amzn"] = "corretto",
    ["albba"] = "dragonwell",
    ["graal"] = "graalvm",
    ["graalce"] = "graalvm_community",
    ["oracle"] = "oracle",
    ["kona"] = "kona",
    ["librca"] = "liberica",
    ["nik"] = "liberica_native",
    ["mandrel"] = "mandrel",
    ["ms"] = "microsoft",
    ["sapmchn"] = "sap_machine",
    ["sem"] = "semeru",
    ["tem"] = "temurin",
    ["trava"] = "trava",
    ["zulu"] = "zulu",
    ["jb"] = "jetbrains",
}

local long_name = {}
local distribution_version = {
    distributions = {},
}

for k, v in pairs(short_name) do
    long_name[v] = k
    table.insert(distribution_version.distributions, {
        name = v,
        short_name = k,
    })
end

function distribution_version.parse_distribution(name)
    local distribution_name = long_name[name]
    if distribution_name then
        -- already a valid long name, just return it
        return {
            name = name,
            short_name = distribution_name,
        }
    end
    distribution_name = short_name[name]
    if distribution_name then
        -- already a valid short name, just return it
        return {
            name = distribution_name,
            short_name = name,
        }
    end
    return nil
end

--- Converts user-input version format to Foojay API format
--- Examples: "26.ea.1" -> "26-ea+1", "26.ea" -> "26-ea", "25.0.3" -> "25.0.3"
--- @param version string User-input version
--- @return string Converted version for Foojay API
function distribution_version.convert_version_for_api(version)
    -- Handle EA version format: "X.ea.Y" -> "X-ea+Y"
    local ea_version, ea_build = version:match("^(%d+)%.ea%.(%d+)$")
    if ea_version and ea_build then
        return ea_version .. "-ea+" .. ea_build
    end

    -- Handle EA version format without build number: "X.ea" -> "X-ea"
    local ea_version_only = version:match("^(%d+)%.ea$")
    if ea_version_only then
        return ea_version_only .. "-ea"
    end

    -- Return as-is for normal versions
    return version
end

--- Reports whether a GraalVM version is a feature release. Since 25.1, GraalVM
--- puts one out every month on top of its 25.0 line, numbered in the second
--- component (25.1.3, 25.4.4.1), which the 25.0 line keeps at 0 (25.0.4.1) or
--- leaves out (25).
--- @param version string Foojay java_version
--- @return boolean
function distribution_version.is_feature_release(version)
    return version:match("^%d+%.[1-9]") ~= nil
end

function distribution_version.parse_version(arg)
    local version_parts = strings.split(arg, "-")
    local version
    local distribution
    local javafx_bundled = false

    -- Check if the last part is "fx" and remove it, setting javafx_bundled flag
    if version_parts[#version_parts] == "fx" then
        javafx_bundled = true
        table.remove(version_parts)
    end

    if not version_parts[2] then
        -- no parts, check if we got a distribution name without version
        distribution = distribution_version.parse_distribution(version_parts[1])
        if not distribution then
            -- no valid distribution found, handle as version with distribution "openjdk"
            version = version_parts[1]
            distribution = distribution_version.parse_distribution("openjdk")
        end
    else
        -- check if the distribution is in the second part of the string (vfox/sdkman default)
        distribution = distribution_version.parse_distribution(version_parts[2])
        if distribution then
            -- valid distribution found, treat first part as version
            version = version_parts[1]
        else
            -- check if the distribution is in the first part of the string (asdf default)
            distribution = distribution_version.parse_distribution(version_parts[1])
            if distribution then
                -- valid distribution found, treat second part as version
                version = version_parts[2]
            else
                -- invalid distribution name
                return nil
            end
        end
    end

    -- A distribution alone (tem, zulu-fx), or after an empty version (-tem,
    -- temurin-), names no version: leave it nil for the hooks to reject.
    if version == "" then
        version = nil
    end
    if version then
        -- Convert version format for Foojay API
        version = distribution_version.convert_version_for_api(version)
    end

    return {
        version = version,
        distribution = distribution,
        javafx_bundled = javafx_bundled,
    }
end

--- Returns the error for a user-input version that parse_version read
--- without a version, such as tem: it names no JDK to install or use.
--- @param arg string User-input version
--- @param parsed table What parse_version returned for arg
--- @return string Error message
function distribution_version.missing_version_error(arg, parsed)
    local short_name = parsed.distribution.short_name
    return "No version in "
        .. arg
        .. "; add one, such as 21-"
        .. short_name
        .. (parsed.javafx_bundled and "-fx" or "")
        .. ". Please check available versions with 'vfox search java "
        .. short_name
        .. "'"
end

return distribution_version
