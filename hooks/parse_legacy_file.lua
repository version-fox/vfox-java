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

        if vendor == "open" and not strings.contains(v, "-") and strings.has_prefix(v, version) then
            targetVersion = v
            break
        end

        if strings.has_suffix(v, "-" .. vendor) then
            if strings.has_prefix(v, version) then
                targetVersion = v
                break
            end
        end
    end

    if not targetVersion then
        for _, v in ipairs(versions) do
            if vendor == "open" and not strings.contains(v, "-") and strings.has_prefix(v, majorVersion .. ".") then
                targetVersion = v
                break
            end

            if strings.has_suffix(v, "-" .. vendor) then
                if strings.has_prefix(v, majorVersion .. ".") then
                    targetVersion = v
                    break
                end
            end
        end
    end

    return {
        version = targetVersion,
    }
end
