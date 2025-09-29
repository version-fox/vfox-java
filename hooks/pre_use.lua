local distribution_version_parser = require("distribution_version")

function PLUGIN:PreUse(ctx)
    local distribution_version = distribution_version_parser.parse_version(ctx.version)
    if distribution_version and distribution_version.distribution.short_name ~= "open" then
        return {
            version = distribution_version.version .. "-" .. distribution_version.distribution.short_name
        }
    else
        return {
            version = ctx.version,
        }
    end
end

