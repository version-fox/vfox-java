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

local distribution_version_parser = require("distribution_version")

--- Compares the numbers in two version strings one by one, missing ones as 0.
local function compare(a, b)
    local x, y = {}, {}
    for number in a:gmatch("%d+") do
        table.insert(x, tonumber(number))
    end
    for number in b:gmatch("%d+") do
        table.insert(y, tonumber(number))
    end
    for i = 1, math.max(#x, #y) do
        if (x[i] or 0) ~= (y[i] or 0) then
            return (x[i] or 0) > (y[i] or 0) and 1 or -1
        end
    end
    return 0
end

--- Whether Java version a is newer than b: the release decides, then the
--- build (21.0.12.1+1 > 21.0.8+9 > 21.0.8+7 > 21+35).
local function newer(a, b)
    local a_release, a_build = a:match("^([^+]*)(.*)$")
    local b_release, b_build = b:match("^([^+]*)(.*)$")
    local order = compare(a_release, b_release)
    return order > 0 or order == 0 and compare(a_build, b_build) > 0
end

--- Returns the installed version that version .. suffix names. vfox uses the
--- returned version as is, while installed names carry the build number
--- PreInstall found, which the input may leave out. So, like PreInstall, take
--- the newest build of a release (21.0.8-tem selects 21.0.8+9-tem) and the
--- newest release of a bare major (21-tem selects 21.0.12.1+1-tem), unless the
--- name itself is installed. Without a match, return the name for vfox to
--- report as not installed.
local function installed_version(installed_sdks, version, suffix)
    local name = version .. suffix
    if installed_sdks[name] then
        return name
    end
    -- A bare major takes any release of it (21.0.12.1+1 for 21) but no EA build
    -- (26-ea+13 for 26); other versions take only a build number (not
    -- 21.0.12.1+1 for 21.0.12, nor 21.0.12+8 for 21.0.1).
    local more = version:match("^%d+$") and "^[.+][%d.+]*$" or "^%+%d+$"
    local best, best_version
    for candidate in pairs(installed_sdks) do
        local java_version = candidate:sub(1, #candidate - #suffix)
        if
            java_version .. suffix == candidate
            and java_version:sub(1, #version) == version
            and java_version:sub(#version + 1):find(more)
            and (not best or newer(java_version, best_version))
        then
            best, best_version = candidate, java_version
        end
    end
    return best or name
end

function PLUGIN:PreUse(ctx)
    local input_version = ctx.version
    local distribution_version = distribution_version_parser.parse_version(input_version)

    -- If it is a pure numeric major version (such as "8"), let the core perform
    -- fuzzy matching, which takes any distribution. Spelled as OpenJDK (8-open,
    -- openjdk-8), it selects the newest OpenJDK release below instead.
    if input_version:match("^%d+$") then
        -- Return no result, let vfox core perform fuzzy matching. Not "": vfox
        -- after 1.0.12 rejects a bare string ("cannot unmarshal string").
        return nil
    end

    if distribution_version then
        -- OpenJDK versions are installed without a distribution suffix, so
        -- 25.0.2+10-open and openjdk-25.0.2+10 both name 25.0.2+10.
        local suffix = distribution_version.javafx_bundled and "-fx" or ""
        if distribution_version.distribution.short_name ~= "open" then
            suffix = "-" .. distribution_version.distribution.short_name .. suffix
        end
        return {
            version = installed_version(ctx.installedSdks or {}, distribution_version.version, suffix),
        }
    else
        return {
            version = input_version,
        }
    end
end
