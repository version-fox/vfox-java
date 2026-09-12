dofile('tests/support.lua')
PLUGIN = {}
RUNTIME = {osType = 'darwin'}
dofile('hooks/post_install.lua')

local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end
local function command(value)
    assert(os.execute(value) == 0, value)
end
local function write(path, content)
    local file = assert(io.open(path, 'w'))
    assert(file:write(content))
    assert(file:close())
end
local function read(path)
    local file = io.open(path, 'r')
    if not file then return nil end
    local content = file:read('*a')
    file:close()
    return content
end
local base = os.tmpname()
os.remove(base)
base = base .. " JDK's & spaces"
command('mkdir -p ' .. quote(base))
local count = 0
local function fixture(layout)
    count = count + 1
    local root = base .. '/' .. count
    local home = root .. layout
    command('mkdir -p ' .. quote(home .. '/bin') .. ' ' .. quote(home .. '/lib'))
    write(home .. '/bin/java', '#!/bin/sh\nexit 0\n')
    command('chmod +x ' .. quote(home .. '/bin/java'))
    write(home .. '/lib/ct.sym', 'jdk symbols')
    write(home .. '/.metadata', 'hidden metadata')
    command('ln -s java ' .. quote(home .. '/bin/java-link'))
    return root, home
end
local function install(root)
    PLUGIN:PostInstall({sdkInfo = {java = {
        path = root, version = '8.0.482+10-librca', note = '8'
    }}})
end
local ok, err = pcall(function()
    -- The reported Liberica layout, plus existing bundle and flat layouts.
    for _, layout in ipairs({
        '/jdk8u482-lite.jdk', '/jdk-8.jdk/Contents/Home',
        '/jdk-21.0.2.jdk/Contents/Home', '/Contents/Home', '',
        '/vendor-jdk/Contents/Home',
    }) do
        local root = fixture(layout)
        install(root)
        assert(read(root .. '/bin/java'), 'JAVA_HOME/bin/java missing for ' .. layout)
        assert(read(root .. '/lib/ct.sym') == 'jdk symbols', layout)
        assert(read(root .. '/.metadata') == 'hidden metadata', 'hidden file lost')
        command('test -L ' .. quote(root .. '/bin/java-link'))
    end

    -- Refuse ambiguous archives or collisions before moving anything.
    local root, home = fixture('/jdk8u482-lite.jdk')
    command('mkdir -p ' .. quote(root .. '/lib'))
    write(root .. '/lib/keep', 'existing file')
    assert(not pcall(install, root), 'must reject an existing destination')
    assert(read(home .. '/bin/java') and read(root .. '/lib/keep') == 'existing file')
    root, home = fixture('/one.jdk')
    command('mkdir -p ' .. quote(root .. '/two.jdk/bin'))
    write(root .. '/two.jdk/bin/java', '#!/bin/sh\nexit 0\n')
    command('chmod +x ' .. quote(root .. '/two.jdk/bin/java'))
    assert(not pcall(install, root), 'must reject multiple JAVA_HOME candidates')
    assert(read(home .. '/bin/java') and read(root .. '/two.jdk/bin/java'))

    -- Other platforms retain their layout.
    root, home = fixture('/jdk8u482-lite.jdk')
    RUNTIME.osType = 'linux'
    install(root)
    assert(read(home .. '/bin/java') and not read(root .. '/bin/java'))
end)
command('rm -rf ' .. quote(base))
assert(ok, err)
print('PASS: macOS JAVA_HOME layouts, metadata, links and collision checks')
