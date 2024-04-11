local strings = require("vfox.strings")
--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
function PLUGIN:EnvKeys(ctx)
    local mainSdkInfo = ctx.main
    local path = mainSdkInfo.path
    local shortname = strings.split(mainSdkInfo.version, "-")[2]
    local envTable = {
        {
            key = "JAVA_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
    if shortname == "graal" or shortname == "graalce" then
        table.insert(envTable, {
            key = "GRAALVM_HOME",
            value = path
        })
    end
    return envTable
end