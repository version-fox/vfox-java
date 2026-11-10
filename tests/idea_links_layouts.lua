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

-- This file is not named *_test.lua on purpose. It links and unlinks for
-- real, in directories it makes, and `vfox plugin test` disables os.execute.
-- It runs under glua instead, the Lua interpreter vfox embeds:
--   go run github.com/yuin/gopher-lua/cmd/glua@v1.1.1 tests/idea_links_layouts.lua
package.path = "./lib/?.lua;./hooks/?.lua;" .. package.path
PLUGIN = {}
local uname = io.popen("uname -s 2>/dev/null")
local sys = uname and uname:read("*l")
if uname then
    uname:close()
end
RUNTIME = { osType = (sys == "Darwin") and "darwin" or "linux" }
dofile("hooks/post_install.lua")
dofile("hooks/pre_uninstall.lua")

local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end
local function command(value)
    assert(os.execute(value) == 0, value)
end
local function target_of(link)
    local handle = assert(io.popen("readlink " .. quote(link)))
    local target = handle:read("*l")
    handle:close()
    return target
end

local base = os.tmpname()
os.remove(base)
local home = base .. "/home"
local jdk = base .. "/jdk-21.0.8+9-tem"
command("mkdir -p " .. quote(home) .. " " .. quote(jdk .. "/bin"))
local release = assert(io.open(jdk .. "/release", "w"))
assert(release:write('IMPLEMENTOR="Eclipse Adoptium"\nJAVA_RUNTIME_VERSION="21.0.8+9-LTS"\n'))
assert(release:close())
local java = assert(io.open(jdk .. "/bin/java", "w"))
assert(java:write("#!/bin/sh\nexit 0\n"))
assert(java:close())
command("chmod +x " .. quote(jdk .. "/bin/java"))

-- HOME and the flag come from a stubbed environment, which the test owns.
local env = { HOME = home }
local getenv = os.getenv
os.getenv = function(name)
    if env[name] ~= nil then
        if env[name] == false then
            return nil
        end
        return env[name]
    end
    return getenv(name)
end

local cases = 0
-- The flag reads 1, true, yes and on, with blanks and case ignored.
for _, value in ipairs({ "1", "true", "yes", "on", " 1 ", "TRUE" }) do
    env.VFOX_JAVA_JDKS_LINKS = value
    assert(require("idea_links").enabled(), value .. ": expected enabled")
    cases = cases + 1
end
for _, value in ipairs({ "0", "false", "no", "", "2" }) do
    env.VFOX_JAVA_JDKS_LINKS = value
    assert(not require("idea_links").enabled(), tostring(value) .. ": expected disabled")
    cases = cases + 1
end
env.VFOX_JAVA_JDKS_LINKS = false
assert(not require("idea_links").enabled(), "absent: expected disabled")
cases = cases + 1
env.VFOX_JAVA_JDKS_LINKS = "1"

local version = "21.0.8+9-tem"
local jdks = home .. (RUNTIME.osType == "darwin" and "/Library/Java/JavaVirtualMachines" or "/.jdks")
local link = jdks .. "/" .. version

-- Installing links the JDK, and uninstalling removes the link.
PLUGIN:PostInstall({ sdkInfo = { java = { path = jdk, version = version } } })
assert(target_of(link) == jdk, "post_install links")
PLUGIN:PreUninstall({ main = { path = jdk, version = version } })
assert(os.execute("test ! -e " .. quote(link) .. " && test ! -L " .. quote(link)) == 0, "pre_uninstall removes")
cases = cases + 1

-- A real directory of the same name is left alone by both.
command("mkdir -p " .. quote(link))
local keep = assert(io.open(link .. "/release", "w"))
assert(keep:write("user JDK\n"))
assert(keep:close())
PLUGIN:PostInstall({ sdkInfo = { java = { path = jdk, version = version } } })
assert(target_of(link) == nil, "post_install leaves a real directory alone")
local probe = io.open(link .. "/release", "r")
assert(probe and probe:read("*a") == "user JDK\n", "real directory untouched")
probe:close()
PLUGIN:PreUninstall({ main = { path = jdk, version = version } })
probe = io.open(link .. "/release", "r")
assert(probe and probe:read("*a") == "user JDK\n", "pre_uninstall leaves a real directory alone")
probe:close()
cases = cases + 1

-- Without the flag, installing touches nothing.
env.VFOX_JAVA_JDKS_LINKS = false
command("rm -rf " .. quote(jdks))
PLUGIN:PostInstall({ sdkInfo = { java = { path = jdk, version = version } } })
assert(os.execute("test ! -e " .. quote(jdks)) == 0, "disabled: no folder")
PLUGIN:PreUninstall({ main = { path = jdk, version = version } })
cases = cases + 1

os.getenv = getenv
command("rm -rf " .. quote(base))
print("PASS: " .. cases .. " IDEA link layout cases")
