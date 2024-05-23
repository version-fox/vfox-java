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
    local targetVersion
    local versions = ctx:getInstalledVersions()
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
        version = targetVersion
    }
end
