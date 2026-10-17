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
    end

    local lib_c_type = ""
    if os == "linux" then
        lib_c_type = detect_lib_c_type()
    end

    -- A bare major such as 21 matches only its GA build (21+35); latest=available
    -- picks the newest 21.x instead. Longer versions keep matching exactly, as
    -- latest=available would look at the major alone.
    local latest = version:match("^%d+$") and "&latest=available" or ""

    local reqUrl = URL:format(version, distribution, arch, archive_types, os, lib_c_type) .. latest

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
    local result = respBody.result

    return result
end

return foojay
