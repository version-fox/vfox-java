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

-- A package whose download is named after its file, for distributions that
-- list several packages of one version: Gluon GraalVM's builds for JDK 11 and
-- JDK 17, whose JDK Foojay gives as distribution_version, and OJDKBuild's JRE
-- next to its JDK.
local function file(jdk, filename, distribution_version)
    jdk.filename = filename
    jdk.distribution_version = distribution_version
    jdk.links.pkg_info_uri = IDS .. filename
    return jdk
end

-- Foojay answers observed on 2026-10-17 for linux/amd64 tar.gz packages, keyed
-- by "<distribution>[ <version>][ <latest>]", and for windows/amd64 zip and
-- tar.gz packages, keyed by "windows <distribution>[ <version>][ <latest>]"
-- (darwin/amd64: "macos ...").
local foojay = {
    ["temurin 21"] = { pkg("21+35") },
    ["temurin 21 available"] = { pkg("21.0.12.1+1") },
    ["temurin 21.0.8"] = { pkg("21.0.8+9") },
    -- latest=available looks at the major alone.
    ["temurin 21.0.8 available"] = { pkg("21.0.12.1+1") },
    ["graalvm 17"] = {},
    ["graalvm 17 available"] = { pkg("17.0.12") },
    -- Observed on 2026-10-18: Oracle GraalVM's monthly feature releases come
    -- before its 25.0 line, and so do GraalVM Community's, whose 25.0 line
    -- ended with 25.0.2.
    ["graalvm 25 available"] = {
        pkg("25.4.4.1"),
        pkg("25.3.4.1"),
        pkg("25.2.4"),
        pkg("25.1.3"),
        pkg("25.0.4.1"),
        pkg("25.0.4"),
    },
    ["graalvm 25.4.4.1"] = { pkg("25.4.4.1") },
    ["graalvm_community 25 available"] = {
        pkg("25.4.4.1"),
        pkg("25.3.4.1"),
        pkg("25.2.4"),
        pkg("25.1.3"),
        pkg("25.0.2"),
    },
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
    ["windows graalvm 25 available"] = {
        pkg("25.4.4.1", false, "zip"),
        pkg("25.3.4.1", false, "zip"),
        pkg("25.2.4", false, "zip"),
        pkg("25.1.3", false, "zip"),
        pkg("25.0.4.1", false, "zip"),
        pkg("25.0.4", false, "zip"),
    },
    ["windows jetbrains"] = {
        pkg("21.0.11+1163116"),
        pkg("21.0.11+1163116", false, "zip"),
        pkg("21.0.8+895146", false, "zip"),
        pkg("21.0.8+895146"),
        pkg("21.0.5+79248"),
    },
    -- Observed on 2026-10-20. Outside Windows, Red Hat ships tar.xz only,
    -- OJDKBuild's Linux builds and OpenLogic's macOS ones are zips, and so are
    -- Gluon GraalVM's releases before 22.1 (macos in front for macOS).
    ["redhat 21 available"] = { pkg("21.0.8+9", false, "tar.xz") },
    ["ojdk_build 11 available"] = { pkg("11.0.15", false, "zip") },
    ["macos openlogic 25 available"] = { pkg("25.0.4+7", false, "zip") },
    -- latest=available answers with one package of the newest release per
    -- archive type, here the JDK 11 build of Gluon's 22.1.0.1, which the JDK
    -- 17 one supersedes, as its JRE does OJDKBuild's 17.0.3 JDK.
    ["gluon_graalvm 22 available"] = {
        file(pkg("22.1.0.1"), "graalvm-svm-java11-linux-gluon-22.1.0.1-Final.tar.gz", "11"),
        file(pkg("22.0.0.3", false, "zip"), "graalvm-svm-java11-linux-gluon-22.0.0.3-Final.zip", "11"),
    },
    ["gluon_graalvm 22.1.0.1"] = {
        file(pkg("22.1.0.1"), "graalvm-svm-java11-linux-gluon-22.1.0.1-Final.tar.gz", "11"),
        file(pkg("22.1.0.1"), "graalvm-svm-java17-linux-gluon-22.1.0.1-Final.tar.gz", "17"),
    },
    ["gluon_graalvm 21 available"] = {
        file(pkg("21.2", false, "zip"), "graalvm-svm-linux-gluon-21.2.0-dev.zip", "21.2"),
        file(pkg("21.1", false, "zip"), "graalvm-svm-linux-gluon-21.1.0-dev.zip", "21.1"),
    },
    ["gluon_graalvm 21.2"] = { file(pkg("21.2", false, "zip"), "graalvm-svm-linux-gluon-21.2.0-dev.zip", "21.2") },
    ["gluon_graalvm"] = {
        file(pkg("23+25"), "graalvm-java23-linux-amd64-gluon-23+25.1-dev.tar.gz", "23"),
        file(pkg("22.1.0.1"), "graalvm-svm-java11-linux-gluon-22.1.0.1-Final.tar.gz", "11"),
        file(pkg("22.1.0.1"), "graalvm-svm-java17-linux-gluon-22.1.0.1-Final.tar.gz", "17"),
        file(pkg("21.2", false, "zip"), "graalvm-svm-linux-gluon-21.2.0-dev.zip", "21.2"),
    },
    -- Among OJDKBuild's Windows JDKs Foojay lists JREs, installer bundles, which
    -- have the JDK one directory down, and RHEL 6 builds for Linux.
    ["windows ojdk_build 17 available"] = {
        file(pkg("17.0.3", false, "zip"), "java-17-openjdk-17.0.3.0.6-1.jre.win.x86_64.zip"),
    },
    ["windows ojdk_build 17.0.3"] = {
        file(pkg("17.0.3", false, "zip"), "java-17-openjdk-17.0.3.0.6-1.jre.win.x86_64.zip"),
        file(pkg("17.0.3", false, "zip"), "java-17-openjdk-17.0.3.0.6-1.win.x86_64.zip"),
    },
    ["windows ojdk_build 11.0.14"] = {
        file(pkg("11.0.14", false, "zip"), "java-11-openjdk-11.0.14.9-2.windows.ojdkbuild.x86_64.installer_bundle.zip"),
        file(pkg("11.0.14", false, "zip"), "java-11-openjdk-11.0.14.9-2.windows.ojdkbuild.x86_64.zip"),
    },
    ["windows ojdk_build 8.0.161"] = {
        file(pkg("8.0.161+14", false, "zip"), "java-1.8.0-openjdk-1.8.0.161-3.b14.el6_9.x86_64.zip"),
        file(pkg("8.0.161+14", false, "zip"), "java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip"),
    },
}

-- The 13 distributions added after release 0.6.2, with their Foojay name and the
-- newest release of a major each lists on Linux x64 (2026-10-20). Their
-- versions follow Foojay's java_version, GraalVM's own numbers for GraalVM CE
-- and Gluon GraalVM.
local others = {
    { "adpt", "aoj", "16.0.1" },
    { "adptj9", "aoj_openj9", "16.0.1" },
    { "eliya", "eliya", "25.0.3" },
    { "gln", "gluon_graalvm", "23+25" },
    { "grl8", "graalvm_ce8", "21.3.1" },
    { "grl11", "graalvm_ce11", "22.3.3" },
    { "grl16", "graalvm_ce16", "21.2" },
    { "grl17", "graalvm_ce17", "22.3.3" },
    { "grl19", "graalvm_ce19", "22.3.1" },
    { "ojdkbld", "ojdk_build", "11.0.15", "zip" },
    { "opnlgc", "openlogic", "25.0.4+7" },
    { "rdht", "redhat", "21.0.8+9", "tar.xz" },
    { "semcrt", "semeru_certified", "25.0.4" },
}
for _, other in ipairs(others) do
    -- OJDKBuild and Gluon GraalVM ask for the newest release itself as well.
    for _, key in ipairs({ other[3]:match("^%d+") .. " available", other[3] }) do
        key = other[2] .. " " .. key
        foojay[key] = foojay[key] or { pkg(other[3], false, other[4]) }
    end
end

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
                if params.operating_system == "windows" or params.operating_system == "macos" then
                    key = params.operating_system .. " " .. key
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

-- Installs version as OJDKBuild's and Gluon GraalVM's bare majors do: the
-- latest=available lookup names the newest release, and a second one asks
-- for that release in full, from which the package of the named file comes.
local function check_release_lookup(version, expected, release, filename)
    requests = {}
    local result = PLUGIN:PreInstall({ version = version })
    assert(result.version == expected, version .. ": expected " .. expected .. ", got " .. tostring(result.version))
    assert(result.url:sub(-#filename) == filename, version .. ": expected " .. filename .. ", got " .. result.url)
    local lookups = {}
    for _, url in ipairs(requests) do
        if url:sub(1, #JDKS) == JDKS then
            table.insert(lookups, url)
        end
    end
    assert(
        #lookups == 2
            and lookups[1]:find("&latest=available", 1, true)
            and lookups[2]:find("?version=" .. release:gsub("%+", "%%2B") .. "&", 1, true)
            and not lookups[2]:find("latest=", 1, true),
        version .. ": unexpected lookups " .. table.concat(lookups, " ")
    )
    cases = cases + 1
end

-- A bare major installs its newest release, not the GA build.
check("21-tem", "21.0.12.1+1-tem", true)
check("temurin-21", "21.0.12.1+1-tem", true)
check("21", "21.0.2+13", true)
check("21-zulu", "21.0.12.1+1-zulu", true)
check("21-zulu-fx", "21.0.12.1+1-zulu-fx", true)
-- Foojay lists no GraalVM 17 GA build, so this found nothing before.
check("17-graal", "17.0.12-graal", true)
-- Oracle GraalVM's bare major takes the newest build of its 25.0 line, not a
-- monthly feature release, which installs when named in full.
check("25-graal", "25.0.4.1-graal", true)
check("graalvm-25", "25.0.4.1-graal", true)
check("25.4.4.1-graal", "25.4.4.1-graal", false)
-- GraalVM Community's feature releases are the only ones it still updates.
check("25-graalce", "25.4.4.1-graalce", true)
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
check("25-graal", "25.0.4.1-graal", true, "zip")
local jb = {}
for _, item in ipairs(PLUGIN:Available({ args = { "jb" } })) do
    table.insert(jb, item.version)
end
assert(
    table.concat(jb, " ") == "21.0.11+1163116-jb 21.0.8+895146-jb 21.0.5+79248-jb",
    "Available jb on Windows: unexpected " .. table.concat(jb, " ")
)
-- OJDKBuild's bare major installs the JDK, not the JRE that latest=available
-- answers with, and no release installs an installer bundle or a Linux build.
check_release_lookup("17-ojdkbld", "17.0.3-ojdkbld", "17.0.3", "/java-17-openjdk-17.0.3.0.6-1.win.x86_64.zip")
check("11.0.14-ojdkbld", "11.0.14-ojdkbld", false, "windows.ojdkbuild.x86_64.zip")
check("8.0.161-ojdkbld", "8.0.161+14-ojdkbld", false, "b14.ojdkbuild.windows.x86_64.zip")
RUNTIME.osType = "linux"

-- The distributions in others install by their short and long names, each from
-- its own Foojay distribution.
for _, other in ipairs(others) do
    local short, long, release, archive_type = other[1], other[2], other[3], other[4]
    local major = release:match("^%d+")
    if long == "ojdk_build" or long == "gluon_graalvm" then
        check_release_lookup(major .. "-" .. short, release .. "-" .. short, release, "." .. (archive_type or "tar.gz"))
        check_release_lookup(long .. "-" .. major, release .. "-" .. short, release, "." .. (archive_type or "tar.gz"))
    else
        check(major .. "-" .. short, release .. "-" .. short, true, archive_type)
        check(long .. "-" .. major, release .. "-" .. short, true, archive_type)
    end
end
-- Only these distributions ask for another archive type besides tar.gz.
requests = {}
PLUGIN:PreInstall({ version = "21-rdht" })
assert(requests[1]:find("&archive_type=tar.gz&archive_type=tar.xz&", 1, true), "21-rdht: " .. requests[1])
requests = {}
PLUGIN:PreInstall({ version = "21-tem" })
assert(requests[1]:find("&archive_type=tar.gz&operating_system=", 1, true), "21-tem: " .. requests[1])
-- Gluon GraalVM's 22.x releases install their JDK 17 build, which they share a
-- version with the JDK 11 one, listed once by searching.
check_release_lookup("22-gln", "22.1.0.1-gln", "22.1.0.1", "/graalvm-svm-java17-linux-gluon-22.1.0.1-Final.tar.gz")
check_release_lookup("21-gln", "21.2-gln", "21.2", "/graalvm-svm-linux-gluon-21.2.0-dev.zip")
requests = {}
local gluon = PLUGIN:PreInstall({ version = "22.1.0.1-gln" })
assert(gluon.url:find("/graalvm-svm-java17-", 1, true) and #requests == 2, "22.1.0.1-gln: " .. gluon.url)
local gln = {}
for _, item in ipairs(PLUGIN:Available({ args = { "gln" } })) do
    table.insert(gln, item.version)
end
assert(
    table.concat(gln, " ") == "23+25-gln 22.1.0.1-gln 21.2-gln",
    "Available gln: unexpected " .. table.concat(gln, " ")
)
-- OpenLogic installs from a zip on macOS, where it ships no tar.gz.
RUNTIME.osType = "darwin"
check("25-opnlgc", "25.0.4+7-opnlgc", true, "zip")
RUNTIME.osType = "linux"

-- A distribution without a version, alone or after an empty one, asks for a
-- version before any lookup (vfox-java#98). Alone it failed with a Lua error;
-- the empty version reached Foojay, which listed every release, and the newest
-- one installed. Once pcall has caught an error, gopher-lua's http stub keeps
-- the requests table it saw, so it is emptied in place.
for _, case in ipairs({
    {
        "tem",
        "No version in tem; add one, such as 21-tem. Please check available versions with 'vfox search java tem'",
    },
    { "temurin", "No version in temurin; add one, such as 21-tem." },
    { "-tem", "No version in -tem; add one, such as 21-tem." },
    { "temurin-", "No version in temurin-; add one, such as 21-tem." },
    { "zulu-fx", "such as 21-zulu-fx. Please check available versions with 'vfox search java zulu'" },
    { "openjdk", "such as 21-open. Please check available versions with 'vfox search java open'" },
}) do
    for i = #requests, 1, -1 do
        requests[i] = nil
    end
    local ok, err = pcall(PLUGIN.PreInstall, PLUGIN, { version = case[1] })
    assert(not ok and tostring(err):find(case[2], 1, true), case[1] .. ": unexpected " .. tostring(err))
    assert(#requests == 0, case[1] .. ": unexpected lookup " .. tostring(requests[1]))
end

print("PASS: " .. cases .. " PreInstall Foojay lookup cases")
