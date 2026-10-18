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

local function pkg(java_version, fx, archive_type)
    archive_type = archive_type or "tar.gz"
    return {
        java_version = java_version,
        major_version = tonumber(java_version:match("^%d+")),
        javafx_bundled = fx == true,
        archive_type = archive_type,
        links = { pkg_info_uri = IDS .. java_version .. (fx and "-fx" or "") .. "." .. archive_type },
    }
end

local function lts(jdk)
    jdk.term_of_support = "lts"
    return jdk
end

-- Foojay answers observed on 2026-10-17 for linux/amd64 tar.gz packages, keyed
-- by "<distribution>[ <version>][ <latest>]", and for windows/amd64 zip and
-- tar.gz packages, keyed by "windows <distribution>[ <version>][ <latest>]".
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
    ["openjdk 25.0.2"] = { pkg("25.0.2+10") },
    ["openjdk 28-ea"] = { pkg("28-ea+19"), pkg("28-ea+18"), pkg("28-ea+15") },
    ["openjdk 28-ea+15"] = { pkg("28-ea+15") },
    -- JetBrains Runtime has nine 21.0.5 builds; abridged.
    ["jetbrains 21.0.5"] = { pkg("21.0.5+79248"), pkg("21.0.5+76240"), pkg("21.0.5+63130"), pkg("21.0.5+6318") },
    ["jetbrains 21.0.5+63130"] = { pkg("21.0.5+63130") },
    -- Searching asks for no version; abridged.
    ["openjdk"] = { pkg("25.0.2+10"), pkg("21.0.2+13") },
    ["temurin"] = { pkg("25.0.2+10"), pkg("21.0.8+9") },
    -- Observed on 2026-10-18: Foojay marks GraalVM's feature releases LTS, as
    -- 25.0 is, and Mandrel 23.1 LTS, as the JDK 21 it builds on is; abridged.
    ["graalvm"] = { lts(pkg("25.4.4.1")), lts(pkg("25.1.3")), lts(pkg("25.0.4.1")), lts(pkg("25")), pkg("24.0.2") },
    ["graalvm_community"] = { lts(pkg("25.4.4.1")), lts(pkg("25.0.2")) },
    ["mandrel"] = { lts(pkg("23.1.12")) },
    -- JetBrains Runtime ships Windows zips for its newer builds only, and Foojay
    -- lists a version's zip and tar.gz in either order; abridged.
    ["windows jetbrains 21"] = { pkg("21+2121") },
    ["windows jetbrains 21 available"] = { pkg("21.0.11+1163116"), pkg("21.0.11+1163116", false, "zip") },
    ["windows jetbrains 21.0.5"] = { pkg("21.0.5+79248"), pkg("21.0.5+76240") },
    ["windows jetbrains"] = {
        pkg("21.0.11+1163116"),
        pkg("21.0.11+1163116", false, "zip"),
        pkg("21.0.8+895146", false, "zip"),
        pkg("21.0.8+895146"),
        pkg("21.0.5+79248"),
    },
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
                local archive_types = {}
                for key, value in request.url:sub(#JDKS + 1):gmatch("([^&=]+)=([^&]*)") do
                    -- Foojay decodes the query string, reading a bare + as a space.
                    value = value:gsub("%+", " "):gsub("%%(%x%x)", function(hex)
                        return string.char(tonumber(hex, 16))
                    end)
                    params[key] = value
                    if key == "archive_type" then
                        archive_types[value] = true
                    end
                end
                -- A version stops at a space: 21.0.5 63130 matches every 21.0.5 build.
                local version = params.version:match("^[^ ]*")
                local key = params.distribution
                if version ~= "" then
                    key = key .. " " .. version
                end
                if params.latest then
                    key = key .. " " .. params.latest
                end
                if params.operating_system == "windows" then
                    key = "windows " .. key
                end
                -- Only the packages of the archive types asked for are listed.
                local result = {}
                for _, package in ipairs(foojay[key] or {}) do
                    if archive_types[package.archive_type] then
                        table.insert(result, package)
                    end
                end
                body = { result = result }
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
local function check(version, expected, latest, archive_type)
    requests = {}
    local result = PLUGIN:PreInstall({ version = version })
    assert(result.version == expected, version .. ": expected " .. expected .. ", got " .. tostring(result.version))
    if archive_type then
        assert(
            result.url:sub(-#archive_type - 1) == "." .. archive_type,
            version .. ": expected the " .. archive_type .. " package, got " .. result.url
        )
    end
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
-- A build number installs that build, not the newest one of its release.
check("28.ea.15", "28-ea+15", false)
check("21.0.5+63130-jb", "21.0.5+63130-jb", false)
-- OpenJDK versions carry no suffix, however the input spells the distribution.
check("25.0.2-open", "25.0.2+10", false)
check("openjdk-25.0.2", "25.0.2+10", false)

-- Searching lists every release, not only the newest one.
requests = {}
PLUGIN:Available({ args = { "tem" } })
assert(#requests == 1 and not requests[1]:find("latest=", 1, true), "Available: unexpected lookup " .. requests[1])

-- Searching lists OpenJDK versions without a suffix, the way PreInstall names
-- them, so vfox marks them installed whether the query is open, openjdk or all.
local function listed(query)
    local versions = {}
    for _, item in ipairs(PLUGIN:Available({ args = { query } })) do
        versions[item.version] = item.note
    end
    return versions
end
for _, query in ipairs({ "open", "openjdk", "all" }) do
    assert(listed(query)["25.0.2+10"], "Available " .. query .. ": 25.0.2+10 is not listed")
end
local all = listed("all")
assert(all["25.0.2+10-tem"] and all["21.0.8+9-tem"], "Available all: Temurin versions lost their suffix")

-- Searching drops the LTS note from GraalVM's feature releases, each
-- superseded within a month, whether it lists one distribution or all.
-- GraalVM's other releases keep it, and so do Mandrel's, which Mandrel numbers
-- after itself.
for version, note in pairs({
    ["25.4.4.1-graal"] = "",
    ["25.1.3-graal"] = "",
    ["25.0.4.1-graal"] = "LTS",
    ["25-graal"] = "LTS",
    ["25.4.4.1-graalce"] = "",
    ["25.0.2-graalce"] = "LTS",
    ["23.1.12-mandrel"] = "LTS",
}) do
    for _, query in ipairs({ version:match("%-(%a+)$"), "all" }) do
        local got = listed(query)[version]
        assert(got == note, ("Available %s: %s noted %q, want %q"):format(query, version, tostring(got), note))
    end
end

-- Windows asks for zip and tar.gz packages in one lookup: installing takes a
-- version's zip where there is one, and searching lists the releases that ship
-- only as tar.gz too, newest first and each once.
RUNTIME.osType = "windows"
assert(check("21-jb", "21.0.11+1163116-jb", true, "zip") == 1, "21-jb: expected one lookup")
assert(check("21.0.5-jb", "21.0.5+79248-jb", false, "tar.gz") == 1, "21.0.5-jb: expected one lookup")
local jb = {}
for _, item in ipairs(PLUGIN:Available({ args = { "jb" } })) do
    table.insert(jb, item.version)
end
assert(
    table.concat(jb, " ") == "21.0.11+1163116-jb 21.0.8+895146-jb 21.0.5+79248-jb",
    "Available jb on Windows: unexpected " .. table.concat(jb, " ")
)
RUNTIME.osType = "linux"

print("PASS: " .. cases .. " PreInstall Foojay lookup cases")
