local foojay = require("foojay")
local distribution_version_parser = require("distribution_version")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local query = ctx.args[1] or "open"
    local jdks = {}

    if query == "all" then
        for _, distribution in ipairs(distribution_version_parser.distributions) do
            local tempJdks = foojay.fetchtJdkList(distribution.name, "")
            for _, jdk in ipairs(tempJdks) do
                jdk.short = distribution.short_name
                table.insert(jdks, jdk)
            end
        end
    else
        local distribution = distribution_version_parser.parse_distribution(query)
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
        
        -- Add -fx suffix for JavaFX bundled versions
        local fx_suffix = ""
        if jdk.javafx_bundled == true then
            fx_suffix = "-fx"
        end
        
        if query == "all" then
            v = v .. fx_suffix .. "-" .. short
        elseif query == "open" then
            v = v .. fx_suffix
        else
            local distribution = distribution_version_parser.parse_distribution(query)
            if not distribution then
                error("Unsupported distribution: " .. query)
            end
            v = v .. fx_suffix .. "-" .. distribution.short_name
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
