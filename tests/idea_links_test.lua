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

-- The link commands are asserted as exact strings; nothing here executes.
local test = require("vfox.test")
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    env = {
        HOME = "/home/test",
        USERPROFILE = "C:\\Users\\test",
        ProgramFiles = "C:\\Program Files",
    },
})
local idea_links = require("idea_links")

local cases = 0

-- Disabled without the variable: uninstalling then touches nothing.
assert(idea_links.enabled() == false, "disabled without VFOX_JAVA_JDKS_LINKS")
plugin:PreUninstall({ main = { path = "/jdks/21", version = "21.0.8+9-tem" } })
cases = cases + 1

-- Folders per platform. RUNTIME mutation is the documented way to try
-- another platform.
assert(idea_links.dir() == "/home/test/.jdks", "linux dir")
RUNTIME.osType = "darwin"
assert(idea_links.dir() == "/home/test/Library/Java/JavaVirtualMachines", "darwin dir")
RUNTIME.osType = "windows"
assert(idea_links.dir() == "C:\\Users\\test\\.jdks", "windows dir")
RUNTIME.osType = "linux"
cases = cases + 1

assert(idea_links.link_path("21.0.8+9-tem") == "/home/test/.jdks/21.0.8+9-tem", "link name")
assert(idea_links.link_path("") == "", "empty version names nothing")
cases = cases + 1

local link = "/home/test/.jdks/21.0.8+9-tem"
local home = "/vfox/cache/java/v-21.0.8+9-tem/java-21.0.8+9-tem"

-- The Unix command creates the folder, leaves a real directory alone and
-- replaces a link, and the unlink command only ever removes links.
local link_cmd = idea_links.link_command(link, home)
assert(
    link_cmd
        == 'sh -c \'link=$1\ntarget=$2\nparent=$(dirname "$link")\nmkdir -p "$parent"\nif [ -e "$link" ] && [ ! -L "$link" ]; then\n    echo "Not a link, left alone: $link" >&2\n    exit 0\nfi\nrm -f "$link"\nln -s "$target" "$link"\n\' sh \'/home/test/.jdks/21.0.8+9-tem\' \'/vfox/cache/java/v-21.0.8+9-tem/java-21.0.8+9-tem\'',
    "unix link command:\n" .. link_cmd
)
local unlink_cmd = idea_links.unlink_command(link)
assert(
    unlink_cmd
        == "sh -c 'link=$1\nif [ -L \"$link\" ]; then\n    rm -f \"$link\"\nfi\n' sh '/home/test/.jdks/21.0.8+9-tem'",
    "unix unlink command:\n" .. unlink_cmd
)
cases = cases + 1

-- Spaces survive quoting on both shells.
local spaced = idea_links.link_command("/home/a b/.jdks/21-tem", "/opt/my jdk")
assert(spaced:find("'/home/a b/.jdks/21-tem'", 1, true), "unix quotes the link:\n" .. spaced)
assert(spaced:find("'/opt/my jdk'", 1, true), "unix quotes the target:\n" .. spaced)
RUNTIME.osType = "windows"
local win_cmd = idea_links.link_command("C:\\Users\\t\\.jdks\\21-tem", "C:\\Program Files\\Java\\jdk-21")
assert(win_cmd:find('"C:\\Users\\t\\.jdks\\21-tem"', 1, true), "windows quotes the link:\n" .. win_cmd)
assert(
    win_cmd:find('mklink /J "C:\\Users\\t\\.jdks\\21-tem" "C:\\Program Files\\Java\\jdk-21"', 1, true),
    "windows mklink:\n" .. win_cmd
)
assert(win_cmd:find("fsutil reparsepoint query", 1, true), "windows checks for a link first:\n" .. win_cmd)
local win_unlink = idea_links.unlink_command("C:\\Users\\t\\.jdks\\21-tem")
assert(win_unlink:find("fsutil reparsepoint query", 1, true), "windows unlink checks first:\n" .. win_unlink)
assert(win_unlink:find("exit /b 0", 1, true), "windows unlink always succeeds:\n" .. win_unlink)
RUNTIME.osType = "linux"
cases = cases + 1

-- ensure_link/remove_link map the runner's exit code; nothing executes here.
local ran = {}
local function fake_run(code)
    return function(cmd)
        table.insert(ran, cmd)
        return code
    end
end
local ok, err = idea_links.ensure_link("21.0.8+9-tem", home, fake_run(0))
assert(ok and err == nil and #ran == 1, "ensure_link success")
local ok2, err2 = idea_links.ensure_link("21.0.8+9-tem", home, fake_run(1))
assert(not ok2 and err2, "ensure_link failure")
local ok3 = idea_links.remove_link("21.0.8+9-tem", fake_run(0))
assert(ok3, "remove_link success")
local ok4, err4 = idea_links.ensure_link("", home, fake_run(0))
assert(not ok4 and err4, "empty version creates nothing")
cases = cases + 1

print("PASS: " .. cases .. " IDEA link cases")
