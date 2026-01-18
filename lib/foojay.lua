local http = require("http")
local json = require("json")

local foojay = {}

local URL =
"https://api.foojay.io/disco/v3.0/packages/jdks?version=%s&distribution=%s&architecture=%s&archive_type=%s&operating_system=%s&lib_c_type=%s&release_status=ga&directly_downloadable=true"

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

foojay.fetchtJdkList= function (distribution, version)

    local os = RUNTIME.osType
    local arch = RUNTIME.archType
    -- Convert arm64 to aarch64 for foojay API compatibility
    if arch == "arm64" then
        arch = "aarch64"
    end

    if os == "darwin" then
        os = "macos"
    end

    local archive_type = "tar.gz"
    if os == "windows" then
        archive_type = "zip"
        if (arch == "amd64") then
            arch = "x64"
        end
    end

    local lib_c_type = ""
    if os == "linux" then
        lib_c_type = detect_lib_c_type()
    end

    local reqUrl = URL:format(version, distribution, arch, archive_type, os, lib_c_type)

    local resp, err = http.get({
        url = reqUrl
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

return foojay
