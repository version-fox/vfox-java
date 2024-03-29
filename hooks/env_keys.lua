--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
function PLUGIN:EnvKeys(ctx)
    local mainSdkInfo = ctx.main
    local path = mainSdkInfo.path
    return {
        {
            key = "JAVA_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
end