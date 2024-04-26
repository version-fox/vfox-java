local http = require("http")
local json = require("json")

local foojay = {}

local URL =
"https://api.foojay.io/disco/v3.0/packages/jdks?version=%s&distribution=%s&architecture=%s&archive_type=%s&operating_system=%s&lib_c_type=%s&release_status=ga&directly_downloadable=true&latest=available"

foojay.fetchtJdkList= function (distribution, version)

    local os = RUNTIME.osType
    if os == "darwin" then
        os = "macos"
    end

    local archive_type = "tar.gz"
    if os == "windows" then
        archive_type = "zip"
    end

    local lib_c_type = ""
    if os == "linux" then
        lib_c_type = "glibc"
    end

    local reqUrl = URL:format(version, distribution, RUNTIME.archType, archive_type, os, lib_c_type)

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
