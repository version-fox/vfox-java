local distribution_version_parser = require("distribution_version")

function PLUGIN:PreUse(ctx)
    local input_version = ctx.version
    local distribution_version = distribution_version_parser.parse_version(input_version)
    
    -- If it is a pure numeric major version (such as "8"), and the distribution is openjdk, let the core perform fuzzy matching.
    if distribution_version and distribution_version.distribution.short_name == "open" then
        if not string.find(distribution_version.version, "%.") then  -- Pure numbers, no minor versions
            return ""  -- Return empty, let vfox core perform fuzzy matching
        end
    end
    

    if distribution_version and distribution_version.distribution.short_name ~= "open" then
        return {
            version = distribution_version.version .. "-" .. distribution_version.distribution.short_name
        }
    else
        return {
            version = input_version,
        }
    end
end