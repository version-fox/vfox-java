--- !!! DO NOT EDIT OR RENAME !!!
PLUGIN = {}

--- !!! MUST BE SET !!!
--- Plugin name
PLUGIN.name = "java"
--- Plugin version
PLUGIN.version = "0.4.3"
--- Plugin homepage
PLUGIN.homepage = "https://github.com/version-fox/vfox-java"
--- Plugin license, please choose a correct license according to your needs.
PLUGIN.license = "Apache 2.0"
--- Plugin description
PLUGIN.description = "Support for multiple JDK distributions, such as: Oracle, Graalvm, Eclipse & more."


--- !!! OPTIONAL !!!
--[[
NOTE:
    Minimum compatible vfox version.
    If the plugin is not compatible with the current vfox version,
    vfox will not load the plugin and prompt the user to upgrade vfox.
 --]]
PLUGIN.minRuntimeVersion = "0.4.0"

PLUGIN.legacyFilenames = {
    '.sdkmanrc',
}
-- Some things that need user to be attention!
PLUGIN.notes = {
    "Listed below are the supported distributions and their short names.",
    " - Oracle:     x.y.z-oracle",
    " - OpenJDK:    x.y.z-open",
    " - GraalVM:    x.y.z-graal",
    " - Temurin:    x.y.z-tem",
    " - Zulu:       x.y.z-zulu",
    "Others please see: https://github.com/version-fox/vfox-java"

}
