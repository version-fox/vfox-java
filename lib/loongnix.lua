local http = require('http')
local loongnix = {}
local base_url = 'https://ftp.loongnix.cn/Java/'

function loongnix.supported()
    return RUNTIME.osType == 'linux' and RUNTIME.archType == 'loong64'
end

function loongnix.is_distribution(name)
    return name == 'lnxabi1' or name == 'lnxabi2'
        or name == 'loongnix_abi1' or name == 'loongnix_abi2'
end

local function require_platform()
    if not loongnix.supported() then
        error('Loongnix JDKs require linux/loong64')
    end
end

local function get(url)
    local response, err = http.get({url = url})
    if err then error('Failed to fetch Loongnix JDKs: ' .. err) end
    if response.status_code ~= 200 then
        error('Failed to fetch Loongnix JDKs: status_code => ' .. response.status_code)
    end
    return response.body
end

local function numbers(version)
    local result = {}
    for number in version:gmatch('%d+') do table.insert(result, tonumber(number)) end
    return result
end

local function newer(left, right)
    local a, b = numbers(left), numbers(right)
    for i = 1, math.max(#a, #b) do
        if (a[i] or 0) ~= (b[i] or 0) then return (a[i] or 0) > (b[i] or 0) end
    end
    return false
end

local function newer_java(left, right)
    local av, ab = left:match('^(.-)%+(%d+)$')
    local bv, bb = right:match('^(.-)%+(%d+)$')
    if newer(av, bv) then return true end
    if newer(bv, av) then return false end
    return tonumber(ab) > tonumber(bb)
end

-- Parse only GA LoongArch tarballs; exclude MIPS, EA, installers and checksum files.
local function parse(filename, major)
    local release, rest = filename:match('^loongson([%d%.]+)%-(.+)$')
    if not release then release, rest = filename:match('^loongson_openjdk([%d%.]+)%-(.+)$') end
    if not release then return nil end
    local fx = rest:sub(1, 3) == 'fx-'
    if fx then rest = rest:sub(4) end
    local jdk, suffix = rest:match('^jdk([%w%._]+)%-linux%-loongarch64(.*)$')
    local abi
    if suffix == '.tar.gz' then abi = 'lnxabi1'
    elseif suffix == '-glibc2.34.tar.gz' then abi = 'lnxabi2'
    else return nil end
    local version, build = jdk:match('^(%d+%.?[%d%.]*)_(%d+)$')
    if not version then
        local update
        update, build = jdk:match('^8u(%d+)b(%d+)$')
        if update then version = '8.0.' .. update end
    end
    if not version or tonumber(version:match('^%d+')) ~= tonumber(major) then return nil end
    version = version .. '+' .. tonumber(build)
    return {
        version = version .. '-' .. abi .. (fx and '-fx' or ''),
        java_version = version, release = release, abi = abi, fx = fx,
        url = base_url .. 'openjdk' .. major .. '/' .. filename,
        note = 'JDK ' .. version .. '; ' .. (abi == 'lnxabi1' and 'ABI1 (Linux 4.19 UAPI)' or 'ABI2 (Linux 5.10 UAPI, glibc 2.34)')
            .. (fx and '; JavaFX' or ''),
    }
end

local function packages(version)
    require_platform()
    local index = get(base_url)
    local majors, seen = {}, {}
    local requested_major = version and version:match('^(%d+)')
    for major in index:gmatch('href=["\']openjdk(%d+)/["\']') do
        if not seen[major] and (not requested_major or tonumber(major) == tonumber(requested_major)) then
            seen[major] = true
            table.insert(majors, major)
        end
    end
    local result, by_version = {}, {}
    for _, major in ipairs(majors) do
        local body = get(base_url .. 'openjdk' .. major .. '/')
        for filename in body:gmatch('href=["\']([^"\'/]+)["\']') do
            local item = parse(filename, major)
            if item then
                local previous = by_version[item.version]
                if not previous or newer(item.release, previous.release) then by_version[item.version] = item end
            end
        end
    end
    for _, item in pairs(by_version) do table.insert(result, item) end
    table.sort(result, function(a, b)
        if a.java_version ~= b.java_version then return newer_java(a.java_version, b.java_version) end
        return a.version < b.version
    end)
    if #result == 0 then error('No Loongnix JDK packages found; check the requested version and upstream directory format') end
    return result
end

function loongnix.available(query)
    local abi = query == 'loongnix_abi1' and 'lnxabi1' or query == 'loongnix_abi2' and 'lnxabi2' or query
    local result = {}
    for _, item in ipairs(packages()) do
        if not loongnix.is_distribution(abi) or item.abi == abi then
            table.insert(result, {version = item.version, note = item.note})
        end
    end
    return result
end

local function matches(candidate, requested)
    if candidate == requested then return true end
    if candidate:sub(1, #requested) ~= requested then return false end
    local boundary = candidate:sub(#requested + 1, #requested + 1)
    return boundary == '.' or boundary == '+'
end

function loongnix.pre_install(parsed)
    require_platform()
    local abi = parsed.distribution.short_name
    if not loongnix.is_distribution(abi) then
        error('Choose a Loongnix ABI explicitly: run vfox search java and select lnxabi1 or lnxabi2')
    end
    for _, item in ipairs(packages(parsed.version)) do
        if item.abi == abi and item.fx == parsed.javafx_bundled and matches(item.java_version, parsed.version) then
            return {version = item.version, url = item.url, note = item.note}
        end
    end
    error('No Loongnix JDK found for ' .. parsed.version .. '-' .. abi .. (parsed.javafx_bundled and '-fx' or ''))
end

return loongnix
