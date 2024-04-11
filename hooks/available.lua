local foojay = require("foojay")
local shortname = require("shortname")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local distribution = ctx.args[1] or "open"
    local jdks = {}

    if distribution == "all" then
        for short, dist in pairs(shortname) do
            local tempJdks = foojay.fetchtJdkList(dist, "")
            for _, jdk in ipairs(tempJdks) do
                jdk.short = short
                table.insert(jdks, jdk)
            end
        end
    else
        jdks = foojay.fetchtJdkList(shortname[distribution] or error("Unsupported distribution: " .. distribution), "")
    end

    local result = {}
    local seen = {}
    for _, jdk in ipairs(jdks) do
        local v = jdk.java_version
        local short = jdk.short
        if distribution == "all" then
            v = v .. "-" .. short
        elseif distribution == "open" then
            v = v
        else
            v = v .. "-" .. distribution
        end

        if not seen[v] then
            seen[v] = true
            -- check if version exists
            table.insert(result, {
                version = v,
                note = jdk.term_of_support == "lts" and "LTS" or ""
            })
        end

    end
    return result
end
