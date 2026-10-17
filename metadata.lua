-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- !!! DO NOT EDIT OR RENAME !!!
PLUGIN = {}

--- !!! MUST BE SET !!!
--- Plugin name
PLUGIN.name = "java"
--- Plugin version
PLUGIN.version = "0.6.1"
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
    ".sdkmanrc",
}
-- Some things that need user to be attention!
PLUGIN.notes = {
    "Listed below are the supported distributions and their short names.",
    " - Oracle:     x.y.z-oracle",
    " - OpenJDK:    x.y.z-open",
    " - GraalVM:    x.y.z-graal",
    " - Temurin:    x.y.z-tem",
    " - Zulu:       x.y.z-zulu",
    "Others please see: https://github.com/version-fox/vfox-java",
}
