local http = require("http")
local strings = require("vfox.strings")

local loongnix = {}

local FTP_BASE_URL = "http://ftp.loongnix.cn/Java/"

-- Supported major versions on Loongnix
local SUPPORTED_VERSIONS = {8, 11, 17, 21}

-- Parse FTP directory listing to extract tar.gz files
local function parseFtpListing(html)
    local files = {}
    -- Match href links that end with .tar.gz and contain loongarch64
    for filename in string.gmatch(html, 'href="([^"]*loongarch64%.tar%.gz)"') do
        table.insert(files, filename)
    end
    return files
end

-- Parse version info from Loongnix filename
-- Format examples:
-- loongson8.1.11-jdk8u332b09-linux-loongarch64.tar.gz
-- loongson11.6.26-fx-jdk11.0.16_8-linux-loongarch64.tar.gz
-- loongson17.11.21-fx-jdk17.0.12_7-linux-loongarch64.tar.gz
-- loongson21.1.0-fx-jdk21_35-linux-loongarch64.tar.gz
local function parseFilename(filename, majorVersion)
    local javaVersion
    
    if majorVersion == 8 then
        -- Pattern: loongson8.x.x-jdk8u<update>b<build>-linux-loongarch64.tar.gz
        local update, build = string.match(filename, "jdk8u(%d+)b(%d+)")
        if update then
            javaVersion = "8.0." .. update
        end
    else
        -- Pattern: loongsonXX.x.x-fx-jdkXX.Y.Z_N-linux-loongarch64.tar.gz
        -- or: loongsonXX.x.x-jdkXX.Y.Z_N-linux-loongarch64.tar.gz
        local major, minor, patch = string.match(filename, "jdk(%d+)%.(%d+)%.(%d+)")
        if major then
            javaVersion = major .. "." .. minor .. "." .. patch
        end
    end
    
    return javaVersion
end

-- Fetch JDK list for a specific major version
local function fetchVersionList(majorVersion)
    local url = FTP_BASE_URL .. "openjdk" .. majorVersion .. "/"
    
    local resp, err = http.get({
        url = url
    })
    
    if err ~= nil then
        return nil, "Failed to fetch from Loongnix: " .. err
    end
    
    if resp.status_code ~= 200 then
        return nil, "Failed to fetch from Loongnix: status_code => " .. resp.status_code
    end
    
    local files = parseFtpListing(resp.body)
    local jdks = {}
    
    for _, filename in ipairs(files) do
        local javaVersion = parseFilename(filename, majorVersion)
        if javaVersion then
            table.insert(jdks, {
                java_version = javaVersion,
                major_version = majorVersion,
                filename = filename,
                download_url = url .. filename,
                term_of_support = (majorVersion == 8 or majorVersion == 11 or majorVersion == 17 or majorVersion == 21) and "lts" or "",
                distribution = "loongson"
            })
        end
    end
    
    return jdks
end

-- Fetch JDK list from Loongnix FTP
-- @param version: specific version to filter (optional, can be empty string or major version like "17")
loongnix.fetchJdkList = function(version)
    local os = RUNTIME.osType
    local arch = RUNTIME.archType
    
    -- Loongnix only supports Linux on loongarch64
    if os ~= "linux" then
        return {}
    end
    
    -- Check for loongarch64 architecture (might be reported as loong64 or loongarch64)
    if arch ~= "loong64" and arch ~= "loongarch64" then
        return {}
    end
    
    local allJdks = {}
    
    -- Determine which versions to fetch
    local versionsToFetch = SUPPORTED_VERSIONS
    
    -- If a specific major version is requested, only fetch that one
    if version and version ~= "" then
        local majorVersion = tonumber(string.match(version, "^(%d+)"))
        if majorVersion then
            local found = false
            for _, v in ipairs(SUPPORTED_VERSIONS) do
                if v == majorVersion then
                    found = true
                    break
                end
            end
            if found then
                versionsToFetch = {majorVersion}
            end
        end
    end
    
    for _, majorVersion in ipairs(versionsToFetch) do
        local jdks, err = fetchVersionList(majorVersion)
        if jdks then
            for _, jdk in ipairs(jdks) do
                table.insert(allJdks, jdk)
            end
        end
    end
    
    -- Filter by specific version if provided
    if version and version ~= "" then
        local filtered = {}
        for _, jdk in ipairs(allJdks) do
            if strings.has_prefix(jdk.java_version, version) or jdk.java_version == version then
                table.insert(filtered, jdk)
            end
        end
        return filtered
    end
    
    return allJdks
end

-- Check if Loongnix should be used based on architecture
loongnix.isLoongArch = function()
    local arch = RUNTIME.archType
    return arch == "loong64" or arch == "loongarch64"
end

return loongnix
