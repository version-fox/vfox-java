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

local foojay = {}

local URL =
    "https://api.foojay.io/disco/v3.0/packages/jdks?version=%s&distribution=%s&architecture=%s&%s&operating_system=%s&lib_c_type=%s&directly_downloadable=true"

-- Outside Windows a few distributions ship some or all releases in another
-- archive type than tar.gz, which vfox unpacks too: Red Hat's Linux builds
-- are tar.xz, OJDKBuild's Linux builds and OpenLogic's macOS builds zip, and
-- so are Gluon GraalVM's releases before 22.1.
local other_archive_type = {
    redhat = "tar.xz",
    ojdk_build = "zip",
    openlogic = "zip",
    gluon_graalvm = "zip",
}

-- Fixes for the packages Foojay lists for a distribution, each returning the
-- ones to keep.
local fixes = {
    -- Among OJDKBuild's Windows JDKs, Foojay lists JREs
    -- (java-17-openjdk-17.0.3.0.6-1.jre.win.x86_64.zip), installer bundles,
    -- which have the JDK one directory down, and RHEL 6 builds for Linux
    -- (java-1.8.0-openjdk-1.8.0.161-3.b14.el6_9.x86_64.zip).
    ojdk_build = function(packages)
        local result = {}
        for _, package in ipairs(packages) do
            local filename = package.filename or ""
            if
                not filename:find(".jre.", 1, true)
                and not filename:find("installer_bundle", 1, true)
                and not filename:find("%.el%d")
            then
                table.insert(result, package)
            end
        end
        return result
    end,
    -- Gluon GraalVM's 22.x releases come for JDK 11 and JDK 17 under one
    -- java_version, with the JDK as distribution_version (11 and 17 for
    -- 22.1.0.1), so an installed name could not tell them apart; the JDK 17
    -- ones stay.
    gluon_graalvm = function(packages)
        local newest = {}
        for _, package in ipairs(packages) do
            local jdk = tonumber(package.distribution_version) or 0
            newest[package.java_version] = math.max(newest[package.java_version] or 0, jdk)
        end
        local result = {}
        for _, package in ipairs(packages) do
            if (tonumber(package.distribution_version) or 0) == newest[package.java_version] then
                table.insert(result, package)
            end
        end
        return result
    end,
}

--- Detects the libc type on Linux systems (glibc or musl)
--- @return string "glibc" or "musl"
local function detect_lib_c_type()
    local handle = io.popen("ldd --version 2>&1")
    if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result:lower():find("musl") then
            return "musl"
        end
    end
    return "glibc"
end

--- Percent-encodes a query string value. Foojay reads a bare + as a space and
--- drops the build after it, so 21.0.5+63130 would match every 21.0.5 build.
--- @param value string
--- @return string
local function encode(value)
    return (value:gsub("[^%w%-._~]", function(c)
        return ("%%%02X"):format(c:byte())
    end))
end

foojay.fetchtJdkList = function(distribution, version)
    local os = RUNTIME.osType
    local arch = RUNTIME.archType
    -- Convert arm64 to aarch64 for foojay API compatibility
    if arch == "arm64" then
        arch = "aarch64"
    end

    if os == "darwin" then
        os = "macos"
    end

    local archive_types = "archive_type=tar.gz"
    if os == "windows" then
        -- JetBrains Runtime ships Windows zips for its newer builds only. Foojay
        -- lists both archive types in one answer, still newest version first.
        archive_types = "archive_type=zip&archive_type=tar.gz"
        if arch == "amd64" then
            arch = "x64"
        end
    elseif other_archive_type[distribution] then
        archive_types = archive_types .. "&archive_type=" .. other_archive_type[distribution]
    end

    local lib_c_type = ""
    if os == "linux" then
        lib_c_type = detect_lib_c_type()
    end

    -- A bare major such as 21 matches only its GA build (21+35); latest=available
    -- picks the newest 21.x instead. Longer versions keep matching exactly, as
    -- latest=available would look at the major alone.
    local latest = version:match("^%d+$") and "&latest=available" or ""

    local function request(query, latest_query)
        local reqUrl = URL:format(encode(query), distribution, arch, archive_types, os, lib_c_type) .. latest_query

        local resp, err = http.get({
            url = reqUrl,
        })
        if err ~= nil then
            error("Failed to fetch jdk info from foojay: " .. err)
        end
        if resp.status_code ~= 200 then
            error("Failed to fetch jdk info from foojay: status_code =>" .. resp.status_code)
        end

        local respBody = json.decode(resp.body)
        return respBody.result
    end

    local result = request(version, latest)
    local fix = fixes[distribution]
    if fix and result then
        -- latest=available answers with one package of the newest release
        -- per archive type, which may be one the fix drops (OJDKBuild's
        -- 17.0.3 JRE on Windows): ask for that release in full.
        if latest ~= "" and result[1] then
            result = request(result[1].java_version, "") or {}
        end
        result = fix(result)
    end

    return result
end

return foojay
