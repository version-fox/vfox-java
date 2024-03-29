local foojay = require("foojay")
local shortname = require("shortname")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local distribution = ctx.args[1] or "open"
    if not shortname[distribution] then
        error("Unsupport distribution: " .. distribution)
    end
    local jdks = foojay.fetchtJdkList(shortname[distribution], "")

    local result = {}
    for _, jdk in ipairs(jdks) do
        local v = jdk.java_version
        if distribution ~= "open" then
            v = v .. "-" .. distribution
        end
        local note = ""
        if jdk.term_of_support == "lts" then
            note = "LTS"
        end
        table.insert(result, {
            version = v,
            note = note,
        })
    end
    return result
end