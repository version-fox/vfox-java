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

-- An Oracle GraalVM or GraalVM Community package as Foojay listed them on
-- 2026-10-20: the JDK's version, GraalVM's (distribution_version), the term
-- of support and the file, on Linux x64 unless the file says otherwise.
-- Where Foojay lists a file twice, host tells the two downloads apart.
local function graal(java_version, graalvm_version, term, filename, host)
    local jdk = file(pkg(java_version, false, filename:match("%.zip$") and "zip" or nil), filename, graalvm_version)
    jdk.term_of_support = term
    jdk.host = host
    if host then
        jdk.links.pkg_info_uri = IDS .. host .. "/" .. filename
    end
    return jdk
end

-- Oracle GraalVM on Linux x64, in Foojay's order, observed on 2026-10-20
-- before 25.0.5 came out; abridged before 25. The feature releases share Java
-- versions with the 25.0 line, and come first for each. Most files are listed
-- twice, and GA 25 comes as two files.
local graalvm_linux = {
    graal("25.0.4.1", "25.4.4.1.1", "sts", "graalvm-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz"),
    graal("25.0.4.1", "25.3.4.1", "sts", "graalvm-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz"),
    graal("25.0.4.1", "25.0.4.1.1", "lts", "graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz"),
    graal("25.0.4.1", "25.0.4.1", "lts", "graalvm-jdk-25.0.4.1_linux-x64_bin.tar.gz"),
    graal("25.0.4", "25.2.4", "sts", "graalvm-jdk-25i2-25.0.4_linux-x64_bin.tar.gz"),
    graal("25.0.4", "25.0.4", "lts", "graalvm-jdk-25.0.4_linux-x64_bin.tar.gz"),
    graal("25.0.4", "25.0.4", "lts", "graalvm-jdk-25.0.4_linux-x64_bin.tar.gz"),
    graal("25.0.3", "25.1.3", "sts", "graalvm-jdk-25i1-25.0.3_linux-x64_bin.tar.gz"),
    graal("25.0.3", "25.0.3", "lts", "graalvm-jdk-25.0.3_linux-x64_bin.tar.gz"),
    graal("25.0.3", "25.0.3", "lts", "graalvm-jdk-25.0.3_linux-x64_bin.tar.gz"),
    graal("25.0.2", "25.0.2", "lts", "graalvm-jdk-25.0.2_linux-x64_bin.tar.gz"),
    graal("25.0.2", "25.0.2", "lts", "graalvm-jdk-25.0.2_linux-x64_bin.tar.gz"),
    graal("25.0.1", "25.0.1", "lts", "graalvm-jdk-25.0.1_linux-x64_bin.tar.gz"),
    graal("25.0.1", "25.0.1", "lts", "graalvm-jdk-25.0.1_linux-x64_bin.tar.gz"),
    graal("25", "25", "lts", "graalvm-jdk-25.0.0_linux-x64_bin.tar.gz"),
    graal("25", "25", "lts", "graalvm-jdk-25_linux-x64_bin.tar.gz"),
    graal("24.0.2", "24.0.2", "sts", "graalvm-jdk-24.0.2_linux-x64_bin.tar.gz"),
    graal("21.0.12", "21.0.12", "lts", "graalvm-jdk-21.0.12_linux-x64_bin.tar.gz"),
    graal("17.0.12", "17.0.12", "lts", "graalvm-jdk-17.0.12_linux-x64_bin.tar.gz"),
    graal("17.0.11", "17.0.11", "lts", "graalvm-jdk-17.0.11_linux-x64_bin.tar.gz"),
}

-- GraalVM Community on Linux x64, observed on 2026-10-20; abridged before 25.
-- Its feature releases are listed under GraalVM's version, as they used to
-- be, with downloads from GitHub, and again under the JDK's, as Oracle
-- GraalVM's are, from Oracle's GraalVM Download Service; its 25.0 line ended
-- with 25.0.2.
local graalvm_community_linux = {
    graal("25.4.4.1", "25.0.4.1.1", "lts", "graalvm-community-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz", "github"),
    graal("25.3.4.1", "25.0.4.1", "lts", "graalvm-community-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz", "github"),
    graal("25.2.4", "25.0.4", "lts", "graalvm-community-jdk-25i2-25.0.4_linux-x64_bin.tar.gz", "github"),
    graal("25.1.3", "25.0.3", "lts", "graalvm-community-jdk-25i1-25.0.3_linux-x64_bin.tar.gz", "github"),
    graal("25.0.4.1", "25.4.4.1.1", "sts", "graalvm-community-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz", "gds"),
    graal("25.0.4.1", "25.3.4.1", "sts", "graalvm-community-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz", "gds"),
    graal("25.0.4", "25.2.4", "sts", "graalvm-community-jdk-25i2-25.0.4_linux-x64_bin.tar.gz", "gds"),
    graal("25.0.3", "25.1.3", "sts", "graalvm-ce-jdk-25i1-25.0.3_linux-x64_bin.tar.gz", "gds"),
    graal("25.0.2", "25.0.2", "lts", "graalvm-community-jdk-25.0.2_linux-x64_bin.tar.gz"),
    graal("25", "25", "lts", "graalvm-community-jdk-25.0.0_linux-x64_bin.tar.gz"),
    graal("24.0.2", "24.0.2", "sts", "graalvm-community-jdk-24.0.2_linux-x64_bin.tar.gz"),
}

-- The same packages for windows/amd64, where Foojay lists them as zips.
local function zips(list)
    local result = {}
    for _, jdk in ipairs(list) do
        local filename = jdk.filename:gsub("_linux%-x64_bin%.tar%.gz$", "_windows-x64_bin.zip")
        table.insert(result, graal(jdk.java_version, jdk.distribution_version, jdk.term_of_support, filename, jdk.host))
    end
    return result
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
    -- Oracle GraalVM's early-access builds are asked for by version.
    ["graalvm 26-ea+13"] = { graal("26-ea+13", "26", "sts", "graalvm-jdk-26.0.0-ea.13_linux-x64_bin.tar.gz") },
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
    -- Installing Oracle GraalVM or GraalVM Community asks for every package,
    -- as searching does.
    ["graalvm"] = graalvm_linux,
    ["graalvm_community"] = graalvm_community_linux,
    -- JetBrains Runtime ships Windows zips for its newer builds only, and Foojay
    -- lists a version's zip and tar.gz in either order; abridged.
    ["windows jetbrains 21"] = { pkg("21+2121") },
    ["windows jetbrains 21 available"] = { pkg("21.0.11+1163116"), pkg("21.0.11+1163116", false, "zip") },
    ["windows jetbrains 21.0.5"] = { pkg("21.0.5+79248"), pkg("21.0.5+76240") },
    -- Windows lists the same GraalVM packages as zips.
    ["windows graalvm"] = zips(graalvm_linux),
    ["windows graalvm_community"] = zips(graalvm_community_linux),
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

-- A package of Mandrel or Liberica NIK: its JDK, the GraalVM number it goes by,
-- its file and term_of_support.
local function own(java_version, distribution_version, filename, term_of_support, fx)
    local jdk = file(pkg(java_version, fx), filename, distribution_version)
    jdk.term_of_support = term_of_support
    return jdk
end

-- Mandrel's file names carry the JDK major and Mandrel's number in four parts.
local function mandrel(jdk, number, term_of_support)
    local parts = number
    while select(2, parts:gsub("%.", "")) < 3 do
        parts = parts .. ".0"
    end
    return own(jdk, number, ("mandrel-java%s-linux-amd64-%s-Final.tar.gz"):format(jdk, parts), term_of_support)
end

-- BellSoft's file names carry the JDK and NIK's number with BellSoft's build,
-- which distribution_version leaves out, with full- for the JavaFX builds.
local function nik(jdk, number, term_of_support, fx)
    local filename = "bellsoft-liberica-vm-" .. (fx and "full-" or "") .. "openjdk" .. jdk .. "-" .. number
    return own(jdk, number:match("^[^+]*"), filename .. "-linux-amd64.tar.gz", term_of_support, fx)
end

-- Observed on 2026-10-20 for linux/amd64: Foojay gives the numbers Mandrel and
-- Liberica NIK go by as distribution_version, and the JDK as java_version,
-- Mandrel's as the major alone; abridged, in Foojay's order. The plugin asks
-- for them by distribution_version, which lists the packages whose number
-- starts with the numbers given, a missing one counting as 0, so 23.1.12
-- lists 23.1.12.1 as well and 23.1.12.0 does not. A build is ignored.
local own_numbers = {
    mandrel = {
        mandrel("25", "25.0.4.1", "lts"),
        mandrel("25", "25.0.1", "lts"),
        mandrel("24", "24.2.2", "sts"),
        mandrel("22", "24.0.2", "sts"),
        mandrel("22", "24", "sts"),
        mandrel("21", "23.1.12.1", "lts"),
        mandrel("21", "23.1.12", "lts"),
        -- Foojay lists some files twice, as it did Oracle GraalVM 25.0.4.
        mandrel("21", "23.1.12", "lts"),
        mandrel("21", "23.1.8", "lts"),
        mandrel("21", "23.1.3.1", "lts"),
        mandrel("20", "23.0.1.2", "sts"),
        mandrel("17", "23.0.6", "lts"),
        mandrel("17", "23.0.1.2", "lts"),
        mandrel("17", "21.3.6", "lts"),
        mandrel("11", "21.3.6", "lts"),
    },
    liberica_native = {
        nik("25.0.4.1+2", "25.0.4.1+1", "lts"),
        nik("25.0.4.1+2", "25.0.4.1+1", "lts", true),
        -- BellSoft built 25.0.3 twice for the same JDK.
        nik("25.0.3+12", "25.0.3+1", "lts"),
        nik("25.0.3+12", "25.0.3+2", "lts", true),
        nik("25.0.3+12", "25.0.3+2", "lts"),
        nik("25.0.3+12", "25.0.3+1", "lts", true),
        nik("23.0.2+9", "24.1.2+1", "sts"),
        nik("21.0.12.1+2", "23.1.12.1+1", "lts"),
        nik("21.0.8+13", "23.1.8+1", "lts", true),
        nik("21.0.8+13", "23.1.8+1", "lts"),
        nik("20.0.2+10", "23.0.1+1", "lts"),
        nik("17.0.10+13", "23.0.3+1", "lts"),
        nik("17.0.10+13", "22.3.5+1", "sts"),
        nik("17.0.8.1+1", "23.0.1+2", "lts"),
        nik("17.0.8+7", "23.0.1+1", "lts"),
        nik("17.0.5+8", "21.3.3.1+1", "sts"),
        nik("11.0.22+12", "22.3.5+1", "sts"),
        nik("11.0.17+7", "21.3.3.1+1", "sts"),
    },
}

-- Whether Foojay lists a package of own_numbers whose number is
-- distribution_version for the query value asked.
local function own_number_matches(distribution_version, asked)
    local numbers = {}
    for number in distribution_version:gmatch("%d+") do
        table.insert(numbers, tonumber(number))
    end
    local i = 0
    for number in asked:match("^[^+]*"):gmatch("%d+") do
        i = i + 1
        if (numbers[i] or 0) ~= tonumber(number) then
            return false
        end
    end
    return true
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
                local packages = foojay[key] or {}
                if own_numbers[params.distribution] and key == params.distribution then
                    packages = {}
                    local asked = (params.distribution_version or ""):match("^[^ ]*")
                    for _, package in ipairs(own_numbers[params.distribution]) do
                        if own_number_matches(package.distribution_version, asked) then
                            table.insert(packages, package)
                        end
                    end
                end
                -- Only the packages of the archive types asked for are listed,
                -- each a copy, as a decoded answer is.
                local result = {}
                for _, package in ipairs(packages) do
                    if archive_types[package.archive_type] then
                        local copy = {}
                        for field, value in pairs(package) do
                            copy[field] = value
                        end
                        table.insert(result, copy)
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
            -- Only Mandrel and Liberica NIK ask by distribution_version.
            assert(not url:find("distribution_version=", 1, true), version .. ": unexpected lookup " .. url)
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

-- Installs version of Oracle GraalVM or GraalVM Community from the named file.
-- The plugin asks Foojay the question searching asks, as Foojay's answers are
-- cached per question and two of them can disagree for a while.
local function check_graalvm(version, expected, filename)
    local short = require("distribution_version").parse_version(version).distribution.short_name
    requests = {}
    PLUGIN:Available({ args = { short } })
    local searched = requests[1]
    requests = {}
    local result = PLUGIN:PreInstall({ version = version })
    assert(result.version == expected, version .. ": expected " .. expected .. ", got " .. tostring(result.version))
    assert(
        result.url:sub(-#filename - 1) == "/" .. filename,
        version .. ": expected " .. filename .. ", got " .. result.url
    )
    local lookups = {}
    for _, url in ipairs(requests) do
        if url:sub(1, #JDKS) == JDKS then
            table.insert(lookups, url)
        end
    end
    assert(
        #lookups == 1 and lookups[1] == searched,
        version .. ": asked " .. table.concat(lookups, " ") .. ", searching asks " .. searched
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
check_graalvm("17-graal", "17.0.12-graal", "graalvm-jdk-17.0.12_linux-x64_bin.tar.gz")
-- Oracle GraalVM's bare major takes the newest build of its 25.0 line, not a
-- monthly feature release, which installs when named in full.
check_graalvm("25-graal", "25.0.4.1.1-graal", "graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz")
check_graalvm("graalvm-25", "25.0.4.1.1-graal", "graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz")
check_graalvm("25.4.4.1.1-graal", "25.4.4.1.1-graal", "graalvm-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz")
-- Oracle GraalVM and GraalVM Community go by GraalVM's own version, which
-- Foojay gives as distribution_version since 2026-10-20. A version names one
-- release, though 25.0.4.1 shares its Java version with 25.0.4.1.1 and two
-- feature releases, which came first and installed (vfox-java#105).
check_graalvm("25.0.4.1-graal", "25.0.4.1-graal", "graalvm-jdk-25.0.4.1_linux-x64_bin.tar.gz")
check_graalvm("25.0.4.1.1-graal", "25.0.4.1.1-graal", "graalvm-jdk-25.0.4.1.1_linux-x64_bin.tar.gz")
check_graalvm("25.0.4-graal", "25.0.4-graal", "graalvm-jdk-25.0.4_linux-x64_bin.tar.gz")
check_graalvm("25.0.3-graal", "25.0.3-graal", "graalvm-jdk-25.0.3_linux-x64_bin.tar.gz")
-- Zeros padding the release are left out, as Foojay leaves them out of Java
-- versions.
check_graalvm("25.0.4.1.0-graal", "25.0.4.1-graal", "graalvm-jdk-25.0.4.1_linux-x64_bin.tar.gz")
check_graalvm("25.0-graal", "25-graal", "graalvm-jdk-25.0.0_linux-x64_bin.tar.gz")
-- GraalVM Community's feature releases are the only ones it still updates.
-- The newest comes from the GraalVM Download Service, where Foojay links its
-- record under the JDK's version. Foojay lists them under GraalVM's version
-- as well, as it used to, with GitHub downloads, so 25.4.4.1-graalce still
-- installs from there, and a release with a record of each kind installs
-- from the one Foojay lists first.
check_graalvm("25-graalce", "25.4.4.1.1-graalce", "gds/graalvm-community-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz")
check_graalvm(
    "25.4.4.1-graalce",
    "25.4.4.1-graalce",
    "github/graalvm-community-jdk-25i4-25.0.4.1.1_linux-x64_bin.tar.gz"
)
check_graalvm("25.3.4.1-graalce", "25.3.4.1-graalce", "github/graalvm-community-jdk-25i3-25.0.4.1_linux-x64_bin.tar.gz")
check_graalvm("25.0.2-graalce", "25.0.2-graalce", "graalvm-community-jdk-25.0.2_linux-x64_bin.tar.gz")
-- Its 25.0 line ended with 25.0.2, so Foojay's Java version 25.0.4.1 names
-- no release of it, and Oracle GraalVM has no 25.4.4.1.
for distribution, version in pairs({ graalvm_community = "25.0.4.1", graalvm = "25.4.4.1" }) do
    local found = require("foojay").fetchtJdkList(distribution, version)
    assert(#found == 0, distribution .. " " .. version .. ": found " .. tostring(found[1] and found[1].filename))
end
-- Early-access builds go by their Java version.
check("26.ea.13-graal", "26-ea+13-graal", false)
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
-- GraalVM's other releases keep it, and so do Mandrel's, though their GraalVM
-- numbers have a non-zero minor up to 24.
for version, note in pairs({
    ["25.4.4.1.1-graal"] = "",
    ["25.1.3-graal"] = "",
    ["25.0.4.1-graal"] = "LTS",
    ["25-graal"] = "LTS",
    ["25.4.4.1.1-graalce"] = "",
    ["25.3.4.1-graalce"] = "",
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
check_graalvm("25-graal", "25.0.4.1.1-graal", "graalvm-jdk-25.0.4.1.1_windows-x64_bin.zip")
check_graalvm("25-graalce", "25.4.4.1.1-graalce", "gds/graalvm-community-jdk-25i4-25.0.4.1.1_windows-x64_bin.zip")
-- Searching GraalVM lists each release once, under GraalVM's own version and
-- newest first. Of the releases of 25 compared here, the 25.0 line alone has
-- the LTS note. GraalVM Community's 25i4 is listed as 25.4.4.1.1, though
-- Foojay has it as 25.4.4.1 too.
for short, want in pairs({
    graal = "25.4.4.1.1-graal, 25.3.4.1-graal, 25.2.4-graal, 25.1.3-graal, 25.0.4.1.1-graal (LTS), "
        .. "25.0.4.1-graal (LTS), 25.0.4-graal (LTS), 25.0.3-graal (LTS), 25.0.2-graal (LTS), "
        .. "25.0.1-graal (LTS), 25-graal (LTS)",
    graalce = "25.4.4.1.1-graalce, 25.3.4.1-graalce, 25.2.4-graalce, 25.1.3-graalce, 25.0.2-graalce (LTS), "
        .. "25-graalce (LTS)",
}) do
    for _, query in ipairs({ short, "all" }) do
        local entries = {}
        for _, item in ipairs(PLUGIN:Available({ args = { query } })) do
            if item.version:sub(-#short - 1) == "-" .. short and item.version:match("^25") then
                table.insert(entries, item.version .. (item.note == "" and "" or " (" .. item.note .. ")"))
            end
        end
        local got = table.concat(entries, ", ")
        assert(got == want, ("Available %s on Windows lists %s, want %s"):format(query, got, want))
    end
end
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

-- Installs version of Mandrel or Liberica NIK, which the plugin asks Foojay
-- for by distribution_version alone, and checks the end of the file name.
local function check_own_number(version, expected, file_end)
    requests = {}
    local result = PLUGIN:PreInstall({ version = version })
    assert(result.version == expected, version .. ": expected " .. expected .. ", got " .. tostring(result.version))
    assert(result.url:sub(-#file_end) == file_end, version .. ": expected ..." .. file_end .. ", got " .. result.url)
    local asked = require("distribution_version").parse_version(version).version:gsub("%+", "%%2B")
    local lookups = {}
    for _, url in ipairs(requests) do
        if url:sub(1, #JDKS) == JDKS then
            table.insert(lookups, url)
        end
    end
    assert(
        #lookups == 1
            and lookups[1]:find("?version=&", 1, true)
            and lookups[1]:sub(-#asked - 22) == "&distribution_version=" .. asked
            and not lookups[1]:find("latest=", 1, true),
        version .. ": unexpected lookups " .. table.concat(lookups, " ")
    )
    cases = cases + 1
end

-- Mandrel and Liberica NIK install by the GraalVM numbers they go by, which
-- Foojay gave as java_version until October 2026 and now as
-- distribution_version (vfox-java#106). A longer version takes the release it
-- names, though Foojay lists 23.1.12.1 for 23.1.12 as well.
check_own_number("23.1.12-mandrel", "23.1.12-mandrel", "java21-linux-amd64-23.1.12.0-Final.tar.gz")
check_own_number("mandrel-23.1.12", "23.1.12-mandrel", "java21-linux-amd64-23.1.12.0-Final.tar.gz")
check_own_number("23.1.12.0-mandrel", "23.1.12-mandrel", "java21-linux-amd64-23.1.12.0-Final.tar.gz")
check_own_number("23.1.12.1-mandrel", "23.1.12.1-mandrel", "java21-linux-amd64-23.1.12.1-Final.tar.gz")
check_own_number("23.1.8-nik", "23.1.8-nik", "vm-openjdk21.0.8+13-23.1.8+1-linux-amd64.tar.gz")
check_own_number("23.1.8-nik-fx", "23.1.8-nik-fx", "vm-full-openjdk21.0.8+13-23.1.8+1-linux-amd64.tar.gz")
-- A bare major is theirs, not the JDK's, and takes the newest release, which
-- latest=available does not find: it answered 23.1.8 for 21 and 25.0.1 for 25.
check_own_number("23-mandrel", "23.1.12.1-mandrel", "java21-linux-amd64-23.1.12.1-Final.tar.gz")
check_own_number("25-mandrel", "25.0.4.1-mandrel", "java25-linux-amd64-25.0.4.1-Final.tar.gz")
check_own_number("24-mandrel", "24.2.2-mandrel", "java24-linux-amd64-24.2.2.0-Final.tar.gz")
check_own_number("23-nik", "23.1.12.1-nik", "vm-openjdk21.0.12.1+2-23.1.12.1+1-linux-amd64.tar.gz")
-- A release that comes for several JDKs installs the build for the newest.
check_own_number("21-mandrel", "21.3.6-mandrel", "java17-linux-amd64-21.3.6.0-Final.tar.gz")
check_own_number("23.0.1.2-mandrel", "23.0.1.2-mandrel", "java20-linux-amd64-23.0.1.2-Final.tar.gz")
check_own_number("liberica_native-21", "21.3.3.1-nik", "vm-openjdk17.0.5+8-21.3.3.1+1-linux-amd64.tar.gz")
check_own_number("22.3.5-nik", "22.3.5-nik", "vm-openjdk17.0.10+13-22.3.5+1-linux-amd64.tar.gz")
check_own_number("23.0.1-nik", "23.0.1-nik", "vm-openjdk20.0.2+10-23.0.1+1-linux-amd64.tar.gz")
-- Of two builds for the same JDK, BellSoft's later one installs.
check_own_number("25.0.3-nik", "25.0.3-nik", "vm-openjdk25.0.3+12-25.0.3+2-linux-amd64.tar.gz")
check_own_number("25.0.3-nik-fx", "25.0.3-nik-fx", "vm-full-openjdk25.0.3+12-25.0.3+2-linux-amd64.tar.gz")

-- Searching lists their releases newest first by those numbers, each once with
-- the LTS note of the build that installs. Foojay lists them by JDK, 23.0.1.2
-- for JDK 20 before 23.0.6 for JDK 17. JavaFX builds come in between.
for short, want in pairs({
    mandrel = "25.0.4.1-mandrel (LTS), 25.0.1-mandrel (LTS), 24.2.2-mandrel, 24.0.2-mandrel, 24-mandrel, "
        .. "23.1.12.1-mandrel (LTS), 23.1.12-mandrel (LTS), 23.1.8-mandrel (LTS), 23.1.3.1-mandrel (LTS), "
        .. "23.0.6-mandrel (LTS), 23.0.1.2-mandrel, 21.3.6-mandrel (LTS)",
    nik = "25.0.4.1-nik (LTS), 25.0.3-nik (LTS), 24.1.2-nik, 23.1.12.1-nik (LTS), 23.1.8-nik (LTS), "
        .. "23.0.3-nik (LTS), 23.0.1-nik (LTS), 22.3.5-nik, 21.3.3.1-nik",
}) do
    for _, query in ipairs({ short, "all" }) do
        local entries = {}
        for _, item in ipairs(PLUGIN:Available({ args = { query } })) do
            local entry = item.version .. (item.note == "" and "" or " (" .. item.note .. ")")
            if item.version:sub(-#short - 1) == "-" .. short then
                table.insert(entries, entry)
            elseif item.version:sub(-#short - 4) == "-" .. short .. "-fx" then
                assert(item.note:find("JavaFX$"), "Available " .. query .. ": " .. entry)
            end
        end
        local got = table.concat(entries, ", ")
        assert(got == want, ("Available %s lists %s, want %s"):format(query, got, want))
    end
end
assert(listed("nik")["23.1.8-nik-fx"] == "LTS, JavaFX", "Available nik: 23.1.8-nik-fx")

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

-- A longer version of Mandrel or Liberica NIK installs only the release it
-- names, which has no build in its name: there is a Mandrel 23.1.3.1 but no
-- 23.1.3, and Liberica NIK 23.1.8 is named 23.1.8-nik.
for _, version in ipairs({ "23.1.3-mandrel", "23.1.8+1-nik", "26-mandrel" }) do
    for i = #requests, 1, -1 do
        requests[i] = nil
    end
    local ok, err = pcall(PLUGIN.PreInstall, PLUGIN, { version = version })
    local want = "No JDK found for " .. version .. " on linux/amd64"
    assert(not ok and tostring(err):find(want, 1, true), version .. ": unexpected " .. tostring(err))
    assert(#requests == 1, version .. ": expected one lookup, got " .. #requests)
end

print("PASS: " .. cases .. " PreInstall Foojay lookup cases")
