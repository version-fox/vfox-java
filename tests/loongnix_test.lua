dofile('tests/support.lua')
local calls = {}
local state = {}
package.preload.http = function()
    return {get = function(request)
        table.insert(calls, request.url)
        assert(request.url:match('^https://ftp%.loongnix%.cn/Java/'), 'unexpected provider: ' .. request.url)
        if state.failure then return state.failure.response, state.failure.err end
        local path = request.url:gsub('https://ftp%.loongnix%.cn/Java/', '')
        if path == '' then path = 'index' else path = path:gsub('/$', '') end
        local f = assert(io.open('tests/fixtures/loongnix/' .. path .. '.html'))
        local body = f:read('*a'); f:close()
        return {status_code = 200, body = body}, nil
    end}
end
package.preload.json = function() return {decode = function() error('Foojay must not be called') end} end
RUNTIME = {osType = 'linux', archType = 'loong64'}
PLUGIN = {}
dofile('hooks/available.lua')
dofile('hooks/pre_install.lua')
dofile('hooks/pre_use.lua')
local versions = PLUGIN:Available({args = {}})
assert(#versions > 0, 'default loong64 search must return versions')
local found = {}
for _, item in ipairs(versions) do
    assert(item.version:match('%-lnxabi[12]'), item.version)
    assert(not found[item.version], 'duplicate version ' .. item.version)
    found[item.version] = true
    local result = PLUGIN:PreUse({version = item.version})
    assert(result.version == item.version, 'PreUse changed ABI or JavaFX suffix')
end
assert(found['21.0.12+8-lnxabi1-fx'])
assert(found['21.0.12+8-lnxabi2-fx'])
assert(found['8.0.502+7-lnxabi2-fx'])
local function check(version, expected, tail)
    local result = PLUGIN:PreInstall({version = version})
    assert(result.version == expected, result.version)
    assert(result.url:sub(-#tail) == tail, result.url)
end
check('21-lnxabi2-fx', '21.0.12+8-lnxabi2-fx', '-loongarch64-glibc2.34.tar.gz')
check('21.0.9+10-lnxabi1-fx', '21.0.9+10-lnxabi1-fx', '-loongarch64.tar.gz')
check('21.0.12+8-loongnix_abi2-fx', '21.0.12+8-lnxabi2-fx', '-loongarch64-glibc2.34.tar.gz')
check('25-lnxabi2-fx', '25.0.4+7-lnxabi2-fx', '-loongarch64-glibc2.34.tar.gz')
check('8-lnxabi2-fx', '8.0.502+7-lnxabi2-fx', '-loongarch64-glibc2.34.tar.gz')
check('17-lnxabi1', '17.0.3+7-lnxabi1', '-loongarch64.tar.gz')
local function rejects(fn, message)
    local ok, err = pcall(fn)
    assert(not ok and tostring(err):find(message, 1, true), tostring(err))
end
rejects(function() PLUGIN:PreInstall({version='999-lnxabi2-fx'}) end, 'No Loongnix JDK')
rejects(function() PLUGIN:PreInstall({version='21'}) end, 'ABI')
rejects(function() PLUGIN:Available({args={'tem'}}) end, 'Foojay')
for _, abi in ipairs({'lnxabi1','lnxabi2'}) do
    for _, item in ipairs(PLUGIN:Available({args={abi}})) do
        assert(item.version:find('-' .. abi, 1, true))
    end
end
assert(#PLUGIN:Available({args={'all'}}) == #versions)
RUNTIME.archType = 'arm64'
rejects(function() PLUGIN:Available({args={'loongnix'}}) end, 'linux/loong64')
RUNTIME.archType = 'loong64'; RUNTIME.osType = 'darwin'
rejects(function() PLUGIN:PreInstall({version='21-lnxabi2-fx'}) end, 'linux/loong64')
RUNTIME.osType = 'linux'
state.failure = {err = 'network unavailable'}
rejects(function() PLUGIN:Available({args={}}) end, 'network unavailable')
state.failure = {response = {status_code=503, body='unavailable'}}
rejects(function() PLUGIN:Available({args={}}) end, '503')
state.failure = {response = {status_code=200, body='<html>unexpected upstream page</html>'}}
rejects(function() PLUGIN:Available({args={}}) end, 'No Loongnix JDK')
state.failure = nil
rejects(function() PLUGIN:PreInstall({version='21.0.1-lnxabi2-fx'}) end, 'No Loongnix JDK')
RUNTIME.archType = 'arm64'
local foojay_calls = {}
require('foojay').fetchtJdkList = function(distribution, version)
    assert(not distribution:match('loongnix'), 'Loongnix leaked into Foojay')
    table.insert(foojay_calls, distribution)
    return {{java_version='21.0.1', term_of_support='lts'}}
end
assert(PLUGIN:Available({args={}})[1].version == '21.0.1')
assert(PLUGIN:Available({args={'tem'}})[1].version == '21.0.1-tem')
assert(#PLUGIN:Available({args={'all'}}) > 0)
assert(#foojay_calls > 2)
print('PASS: Loongnix hook regression tests (' .. #versions .. ' fixture versions)')
