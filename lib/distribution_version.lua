local strings = require("vfox.strings")

local short_name = {
    ["open"] = "openjdk",
    ["bsg"] = "bisheng",
    ["amzn"] = "corretto",
    ["albba"] = "dragonwell",
    ["graal"] = "graalvm",
    ["graalce"] = "graalvm_community",
    ["oracle"] = "oracle",
    ["kona"] = "kona",
    ["librca"] = "liberica",
    ["nik"] = "liberica_native",
    ["mandrel"] = "mandrel",
    ["ms"] = "microsoft",
    ["sapmchn"] = "sap_machine",
    ["sem"] = "semeru",
    ["tem"] = "temurin",
    ["trava"] = "trava",
    ["zulu"] = "zulu",
    ["jb"] = "jetbrains",
}

local long_name={}
local distribution_version={
    distributions={}
}

for k,v in pairs(short_name) do
    long_name[v]=k
    table.insert(distribution_version.distributions,{
        name = v,
        short_name = k
    })
end

function distribution_version.parse_distribution (name)
    local distribution_name=long_name[name]
    if distribution_name then
        -- already a valid long name, just return it
        return {
            name = name,
            short_name = distribution_name
        }
    end
    distribution_name=short_name[name]
    if distribution_name then
        -- already a valid short name, just return it
        return {
            name = distribution_name,
            short_name = name
        }
    end
    return nil
end


function distribution_version.parse_version (arg)
    local version_parts = strings.split(arg, "-")
    local version
    local distribution

    if not version_parts[2] then
        -- no parts, check if we got a distribution name without version
        distribution = distribution_version.parse_distribution(version_parts[1])
        if not distribution then
            -- no valid distribution found, handle as version with distribution "openjdk"
            version=version_parts[1]
            distribution = distribution_version.parse_distribution("openjdk")
        end
    else
        -- check if the distribution is in the second part of the string (vfox/sdkman default)
        distribution = distribution_version.parse_distribution(version_parts[2])
        if distribution then
            -- valid distribution found, treat first part as version
            version=version_parts[1]
        else
            -- check if the distribution is in the first part of the string (asdf default)
            distribution = distribution_version.parse_distribution(version_parts[1])
            if distribution then
                -- valid distribution found, treat second part as version
                version=version_parts[2]
            else
                -- invalid distribution name
                return nil
            end
        end
    end

    return {
        version = version,
        distribution = distribution,
    }
end

return distribution_version
