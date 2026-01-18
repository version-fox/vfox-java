local foojay = require("foojay")
local distribution_version_parser = require("distribution_version")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local query = ctx.args[1] or "open"
    local jdks = {}
    local distribution = nil

    if query == "all" then
        for _, dist in ipairs(distribution_version_parser.distributions) do
            local tempJdks = foojay.fetchtJdkList(dist.name, "")
            for _, jdk in ipairs(tempJdks) do
                jdk.short = dist.short_name
                table.insert(jdks, jdk)
            end
        end
    else
        distribution = distribution_version_parser.parse_distribution(query)
        if not distribution then
            error("Unsupported distribution: " .. query)
        end
        jdks = foojay.fetchtJdkList(distribution.name, "")
    end

    local result = {}
    local seen = {}
    for _, jdk in ipairs(jdks) do
        local v = jdk.java_version
        local short = jdk.short
        
        -- Add -fx suffix for JavaFX bundled versions (after distribution name)
        local fx_suffix = ""
        if jdk.javafx_bundled == true then
            fx_suffix = "-fx"
        end
        
        if query == "all" then
            v = v .. "-" .. short .. fx_suffix
        elseif query == "open" then
            v = v .. fx_suffix
        else
            v = v .. "-" .. distribution.short_name .. fx_suffix
        end

        if not seen[v] then
            seen[v] = true
            -- check if version exists
            local note = jdk.term_of_support == "lts" and "LTS" or ""
            if jdk.javafx_bundled == true then
                note = note == "" and "JavaFX" or note .. ", JavaFX"
            end
            table.insert(result, {
                version = v,
                note = note
            })
        end

    end
    return result
end
