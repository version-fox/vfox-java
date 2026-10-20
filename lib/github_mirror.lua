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

--- Downloads from GitHub through a mirror, for those who reach github.com
--- slowly. Many distributions publish their JDKs as GitHub releases: Foojay
--- links Temurin, Liberica and GraalVM Community there, for instance.
---
--- $VFOX_JAVA_GITHUB_MIRROR holds a URL prefix, such as https://gh-proxy.org/,
--- that goes in front of the whole GitHub URL, the way vfox-flutter does with
--- $VFOX_FLUTTER_GITHUB_MIRROR. URLs of other hosts stay as they are.
local github_mirror = {}

local ENV = "VFOX_JAVA_GITHUB_MIRROR"
local GITHUB = "https://github.com/"

--- Returns the URL to download from: url behind the mirror if the variable is
--- set and url is on GitHub, else url, whatever it is.
--- @param url string|nil
--- @return string|nil
function github_mirror.url(url)
    if type(url) ~= "string" or url:sub(1, #GITHUB) ~= GITHUB then
        return url
    end
    local prefix = (os.getenv(ENV) or ""):match("^%s*(.-)%s*$")
    if prefix == "" then
        return url
    end
    -- vfox downloads what starts with http:// or https:// and takes anything
    -- else for a file on disk, which it then fails to move.
    if not prefix:find("^https?://") then
        error(ENV .. " must start with http:// or https://, such as https://gh-proxy.org/, but is " .. prefix)
    end
    if prefix:sub(-1) ~= "/" then
        prefix = prefix .. "/"
    end
    return prefix .. url
end

return github_mirror
