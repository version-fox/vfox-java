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

--- Opt-in links in the folder IntelliJ IDEA and Gradle look in (`~/.jdks`,
--- `~/Library/Java/JavaVirtualMachines` on macOS, `%USERPROFILE%\.jdks` on
--- Windows), so that they find every JDK vfox installed. Enable with
--- VFOX_JAVA_JDKS_LINKS=1. The link carries the installed version's name;
--- uninstalling removes the link it created and nothing else.
local idea_links = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(value)
    return (value or ""):lower()
end

--- Whether link maintenance is enabled.
function idea_links.enabled()
    local value = lower(trim(os.getenv("VFOX_JAVA_JDKS_LINKS") or ""))
    return value == "1" or value == "true" or value == "yes" or value == "on"
end

--- Platform separator and join, as in lib/detect_jdk.lua.
local function sep()
    if RUNTIME and RUNTIME.osType == "windows" then
        return "\\"
    end
    return "/"
end

local function join(left, right)
    local s = sep()
    if left:sub(-1) == "/" or left:sub(-1) == "\\" then
        return left .. right
    end
    return left .. s .. right
end

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function cmd_quote(value)
    return '"' .. value:gsub('"', '""') .. '"'
end

--- The folder that holds the links.
function idea_links.dir()
    local home
    if RUNTIME and RUNTIME.osType == "windows" then
        home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
        if home == "" then
            return ""
        end
        return join(home, ".jdks")
    end
    home = os.getenv("HOME") or ""
    if home == "" then
        return ""
    end
    if RUNTIME and RUNTIME.osType == "darwin" then
        return join(home, "Library/Java/JavaVirtualMachines")
    end
    return join(home, ".jdks")
end

--- The link for an installed version name, or "".
function idea_links.link_path(version)
    local dir = idea_links.dir()
    if dir == "" or version == nil or version == "" then
        return ""
    end
    return join(dir, version)
end

--- Shell command creating link -> target. Where something that is not a
--- link already has the name, it is left alone and the command still exits
--- 0, so a JDK of the user's own is never touched.
function idea_links.link_command(link, target)
    if RUNTIME and RUNTIME.osType == "windows" then
        local parent = link:match("^(.*)\\[^\\]+$") or link:match("^(.*)/[^/]+$") or ""
        return "mkdir "
            .. cmd_quote(parent)
            .. " 2>nul & if exist "
            .. cmd_quote(link)
            .. " (fsutil reparsepoint query "
            .. cmd_quote(link)
            .. " >nul 2>&1 || (echo Not a link, left alone: "
            .. link
            .. " 1>&2 & exit /b 0)) & rmdir "
            .. cmd_quote(link)
            .. " 2>nul & mklink /J "
            .. cmd_quote(link)
            .. " "
            .. cmd_quote(target)
    end
    local script = [[
link=$1
target=$2
parent=$(dirname "$link")
mkdir -p "$parent"
if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "Not a link, left alone: $link" >&2
    exit 0
fi
rm -f "$link"
ln -s "$target" "$link"
]]
    return "sh -c " .. shell_quote(script) .. " sh " .. shell_quote(link) .. " " .. shell_quote(target)
end

--- Shell command removing link where it is a link. A real directory is left
--- alone, and the command always exits 0, so cleanup never blocks an
--- uninstall.
function idea_links.unlink_command(link)
    if RUNTIME and RUNTIME.osType == "windows" then
        return "fsutil reparsepoint query "
            .. cmd_quote(link)
            .. " >nul 2>&1 && rmdir "
            .. cmd_quote(link)
            .. " 2>nul & exit /b 0"
    end
    local script = [[
link=$1
if [ -L "$link" ]; then
    rm -f "$link"
fi
]]
    return "sh -c " .. shell_quote(script) .. " sh " .. shell_quote(link)
end

--- Creates the link for an installed version. run executes one shell
--- command and returns its exit code; it defaults to os.execute.
--- @return boolean, string|nil
function idea_links.ensure_link(version, home, run)
    run = run or function(cmd)
        return os.execute(cmd)
    end
    local link = idea_links.link_path(version)
    if link == "" or home == nil or home == "" then
        return false, "no link directory or JDK home"
    end
    if run(idea_links.link_command(link, home)) ~= 0 then
        return false, "could not create " .. link
    end
    return true
end

--- Removes the link of an uninstalled version where it is a link.
--- @return boolean, string|nil
function idea_links.remove_link(version, run)
    run = run or function(cmd)
        return os.execute(cmd)
    end
    local link = idea_links.link_path(version)
    if link == "" then
        return false, "no link directory"
    end
    if run(idea_links.unlink_command(link)) ~= 0 then
        return false, "could not remove " .. link
    end
    return true
end

return idea_links
