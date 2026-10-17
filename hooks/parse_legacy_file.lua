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

--- Rewrites an SDKMAN identifier in the plugin's spelling, which parse_version
--- reads. SDKMAN calls JetBrains jbr (the plugin's jb) and puts fx in the
--- version of JavaFX builds: 21.0.12.fx-zulu, or 21.0.12-fx+1.1-librca in its
--- semverish identifiers (the plugin's 21.0.12-zulu-fx, 21.0.12+1.1-librca-fx).
--- Any other spelling, the plugin's own included, is returned unchanged.
local function plugin_spelling(identifier)
    local version, distribution = identifier:match("^(.+)%-([^-]+)$")
    if not version then
        return identifier
    end
    if distribution == "jbr" then
        distribution = "jb"
    end
    local release, build = version:match("^(%d[%d.]*)[.-]fx(.*)$")
    if release then
        return release .. build .. "-" .. distribution .. "-fx"
    end
    return version .. "-" .. distribution
end

function PLUGIN:ParseLegacyFile(ctx)
    local filepath = ctx.filepath

    --- 17.0.10-librca
    --- 17.0.10+20-librca
    local javaVersion

    for line in io.lines(filepath) do
        if strings.has_prefix(line, "java=") then
            javaVersion = plugin_spelling(strings.trim_prefix(line, "java="))
            break
        end
    end

    if not javaVersion then
        return {}
    end

    local distributionVersion = distribution_version_parser.parse_version(javaVersion)
    if not distributionVersion then
        return {}
    end
    local fullVersion = distributionVersion.version
    local vendor = distributionVersion.distribution.short_name
    if not vendor then
        return {}
    end

    local versionArr = strings.split(fullVersion, "+")
    local version = versionArr[1]
    local build = versionArr[2]

    local majorVersion = strings.split(version, ".")[1]

    --- Installed versions end in -<vendor> (OpenJDK's in nothing), then -fx for
    --- JavaFX builds: 21.0.8+9-tem, 21.0.12+7-zulu-fx, 25.0.2+10.
    local suffix = (vendor == "open" and "" or "-" .. vendor) .. (distributionVersion.javafx_bundled and "-fx" or "")

    --- Whether installed version v is of this distribution and JavaFX flavour,
    --- with a Java version starting with prefix.
    local function matches(v, prefix)
        local java_version = v:sub(1, #v - #suffix)
        return java_version .. suffix == v
            and (vendor ~= "open" or not strings.contains(java_version, "-"))
            and strings.has_prefix(java_version, prefix)
    end

    --- Get the list of versions of the current plugin installed
    --- (a plain call: vfox 1.x rejects the extra ctx argument of ctx:...).
    local targetVersion
    local versions = ctx.getInstalledVersions()
    for _, v in ipairs(versions) do
        --- It may be exactly the same, try it first.
        if v == javaVersion then
            targetVersion = v
            break
        end

        if matches(v, version) then
            targetVersion = v
            break
        end
    end

    if not targetVersion then
        for _, v in ipairs(versions) do
            if matches(v, majorVersion .. ".") then
                targetVersion = v
                break
            end
        end
    end

    return {
        version = targetVersion,
    }
end
