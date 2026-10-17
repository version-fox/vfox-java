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

dofile("tests/support.lua")
local JDKS = "https://api.foojay.io/disco/v3.0/packages/jdks?"
local IDS = "https://api.foojay.io/disco/v3.0/ids/"

local function pkg(java_version, fx)
    return {
        java_version = java_version,
        major_version = tonumber(java_version:match("^%d+")),
        javafx_bundled = fx == true,
        links = { pkg_info_uri = IDS .. java_version .. (fx and "-fx" or "") },
    }
end

-- Foojay answers observed on 2026-10-17 for linux/amd64 tar.gz packages, keyed
-- by "<distribution> <version>[ <latest>]".
local foojay = {
    ["temurin 21"] = { pkg("21+35") },
    ["temurin 21 available"] = { pkg("21.0.12.1+1") },
    ["temurin 21.0.8"] = { pkg("21.0.8+9") },
    -- latest=available looks at the major alone.
    ["temurin 21.0.8 available"] = { pkg("21.0.12.1+1") },
    ["graalvm 17"] = {},
    ["graalvm 17 available"] = { pkg("17.0.12") },
    ["zulu 21"] = { pkg("21+35"), pkg("21+35", true) },
    ["zulu 21 available"] = { pkg("21.0.12.1+1"), pkg("21.0.12.1+1", true) },
    ["openjdk 21"] = { pkg("21+35") },
    ["openjdk 21 available"] = { pkg("21.0.2+13") },
    ["openjdk 28-ea"] = { pkg("28-ea+19"), pkg("28-ea+18") },
    ["jetbrains 21"] = { pkg("21+2121") },
    ["jetbrains 21 available"] = { pkg("21.0.11+1163116") },
}

local requests = {}
local responses = {}
package.preload.http = function()
    return {
        get = function(request)
            table.insert(requests, request.url)
            local body
            if request.url:sub(1, #JDKS) == JDKS then
                local params = {}
                for key, value in request.url:sub(#JDKS + 1):gmatch("([^&=]+)=([^&]*)") do
                    params[key] = value
                end
                local key = params.distribution .. " " .. params.version
                if params.latest then
                    key = key .. " " .. params.latest
                end
                -- Only tar.gz packages are listed, so Windows retries every zip lookup with tar.gz.
                body = { result = params.archive_type == "tar.gz" and foojay[key] or {} }
            else
                assert(request.url:sub(1, #IDS) == IDS, "unexpected request: " .. request.url)
                local id = request.url:sub(#IDS + 1)
                body = { result = { { direct_download_uri = "https://download.invalid/" .. id } } }
            end
            table.insert(responses, body)
            return { status_code = 200, body = tostring(#responses) }, nil
        end,
    }
end
package.preload.json = function()
    return {
        decode = function(body)
            return responses[tonumber(body)]
        end,
    }
end
RUNTIME = { osType = "linux", archType = "amd64" }
PLUGIN = {}
dofile("hooks/available.lua")
dofile("hooks/pre_install.lua")

local cases = 0
local function check(version, expected, latest)
    requests = {}
    local result = PLUGIN:PreInstall({ version = version })
    assert(result.version == expected, version .. ": expected " .. expected .. ", got " .. tostring(result.version))
    local lookups = 0
    for _, url in ipairs(requests) do
        if url:sub(1, #JDKS) == JDKS then
            lookups = lookups + 1
            assert((url:find("&latest=available", 1, true) ~= nil) == latest, version .. ": unexpected lookup " .. url)
        end
    end
    assert(lookups > 0, version .. ": no Foojay lookup")
    cases = cases + 1
    return lookups
end

-- A bare major installs its newest release, not the GA build.
check("21-tem", "21.0.12.1+1-tem", true)
check("temurin-21", "21.0.12.1+1-tem", true)
check("21", "21.0.2+13", true)
check("21-zulu", "21.0.12.1+1-zulu", true)
check("21-zulu-fx", "21.0.12.1+1-zulu-fx", true)
-- Foojay lists no GraalVM 17 GA build, so this found nothing before.
check("17-graal", "17.0.12-graal", true)
-- Anything longer than a major still matches exactly.
check("21.0.8-tem", "21.0.8+9-tem", false)
check("28.ea", "28-ea+19", false)
-- On Windows the tar.gz retry keeps asking for the newest release.
RUNTIME.osType = "windows"
assert(check("21-jb", "21.0.11+1163116-jb", true) == 2, "21-jb: expected a zip lookup and a tar.gz retry")
RUNTIME.osType = "linux"

-- Searching lists every release, not only the newest one.
requests = {}
PLUGIN:Available({ args = { "tem" } })
assert(#requests == 1 and not requests[1]:find("latest=", 1, true), "Available: unexpected lookup " .. requests[1])

print("PASS: " .. cases .. " PreInstall Foojay lookup cases")
