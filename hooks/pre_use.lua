--- When user invoke `use` command, this function will be called to get the
--- valid version information.
--- @param ctx table Context information
function PLUGIN:PreUse(ctx)
    local runtimeVersion = ctx.runtimeVersion
    --- user input version
    local version = ctx.version
    --- user current used version
    local previousVersion = ctx.previousVersion

    --- installed sdks
    local sdkInfo = ctx.installedSdks['version']
    local path = sdkInfo.path
    local name = sdkInfo.name
    local version = sdkInfo.version

    --- working directory
    local cwd = ctx.cwd

    --- user input scope
    --- could be one of global/project/session
    local scope = ctx.scope

    --- return the version information
    return {
        version = version,
    }
end