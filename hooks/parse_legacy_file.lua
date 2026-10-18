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

local strings = require("vfox.strings")

local distribution_version_parser = require("distribution_version")
local installed_version = require("installed_version")

--- Rewrites an SDKMAN identifier in the plugin's spelling, which parse_version
--- reads. SDKMAN calls JetBrains jbr (the plugin's jb) and puts fx in the
--- version of JavaFX builds: 21.0.12.fx-zulu, or 21.0.12-fx+1.1-librca in its
--- semverish identifiers (the plugin's 21.0.12-zulu-fx, 21.0.12+1.1-librca-fx).
--- The semverish ones spell early-access builds 28.0.0+ea.19-open, padded or
--- not (28.0.0.0+ea.19-open), where SDKMAN used to write the plugin's
--- 28.ea.19-open (Foojay's 28-ea+19).
--- Any other spelling, the plugin's own included, is returned unchanged.
local function plugin_spelling(identifier)
    local version, distribution = identifier:match("^(.+)%-([^-]+)$")
    if not version then
        return identifier
    end
    if distribution == "jbr" then
        distribution = "jb"
    end
    local suffix = "-" .. distribution
    local release, build = version:match("^(%d[%d.]*)[.-]fx(.*)$")
    if release then
        version, suffix = release .. build, suffix .. "-fx"
    end
    local major, ea_build = version:match("^(%d+)[.0]*%+ea%.(%d+)$")
    if major then
        version = major .. ".ea." .. ea_build
    end
    return version .. suffix
end

function PLUGIN:ParseLegacyFile(ctx)
    local filepath = ctx.filepath

    --- 17.0.10-librca
    --- 17.0.10+20-librca
    local javaVersion

    for line in io.lines(filepath) do
        if strings.has_prefix(line, "java=") then
            javaVersion = strings.trim_prefix(line, "java=")
            break
        end
    end

    if not javaVersion then
        return {}
    end

    --- Get the list of versions of the current plugin installed
    --- (a plain call: vfox 1.x rejects the extra ctx argument of ctx:...).
    --- vfox sorts it as strings, descending (21.0.8+9-tem, 21.0.12+8-tem,
    --- 21.0.1+12-tem), so the first match is not the one to take.
    local installed = {}
    for _, v in ipairs(ctx.getInstalledVersions()) do
        installed[v] = true
    end

    --- An installed version written as vfox lists it selects itself, as in
    --- vfox use, even one that parse_version cannot read: an early-access
    --- build (28-ea+19, 28-ea+18-zulu).
    if installed[javaVersion] then
        return { version = javaVersion }
    end

    local distributionVersion = distribution_version_parser.parse_version(plugin_spelling(javaVersion))
    if not distributionVersion then
        return {}
    end
    local fullVersion = distributionVersion.version
    local vendor = distributionVersion.distribution.short_name
    if not vendor then
        return {}
    end

    --- SDKMAN pads the release with zeros that Foojay, and so the installed
    --- name, leaves out: 27.0.0+36 is 27+36, 25.0.1.0+8 is 25.0.1+8.
    local version, build = installed_version.unpad(fullVersion):match("^([^+]*)(.*)$")
    local majorVersion = strings.split(version, ".")[1]

    --- Installed versions end in -<vendor> (OpenJDK's in nothing), then -fx for
    --- JavaFX builds: 21.0.8+9-tem, 21.0.12+7-zulu-fx, 25.0.2+10.
    local suffix = (vendor == "open" and "" or "-" .. vendor) .. (distributionVersion.javafx_bundled and "-fx" or "")

    --- The version itself (21.0.5+63130-jb), else the release itself or its
    --- newest build, as SDKMAN's build numbers count its own rebuilds
    --- (21.0.12+1.1-tem), else the newest installed release of the major
    --- (21.0.12+8-tem for 21.0.3-tem). A bare major (21-tem) skips the
    --- release, taking the newest one as vfox use java@21-tem does, while
    --- SDKMAN's 21.0.0 still names the release 21 (21+35-tem).
    local name = version .. build .. suffix
    return {
        version = installed[name] and name
            or not fullVersion:match("^%d+$") and installed_version.release(installed, version, suffix)
            or installed_version.major(installed, majorVersion, suffix),
    }
end
