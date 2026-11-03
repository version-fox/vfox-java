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

dofile("tests/support.lua")
local checksum = require("checksum")

local cases = 0

-- The checksum files that Foojay's checksum_uri pointed to on 2026-11-02, one
-- for each way they write a digest.
local GRAALCE = "graalvm-community-jdk-25.0.2_linux-x64_bin.tar.gz"
local GRAALCE_DIGEST = "e0be791c8fda4d03b6b0a0cb824fef3149736170057b3a515252b44419606af0"
local MICROSOFT = "microsoft-jdk-25.0.5.0.2-linux-x64.tar.gz"
local MICROSOFT_DIGEST = "173e8e4286289335b422b591c88a1f553fc44c701a876a7c8dd29037a598fc14"
local JETBRAINS = "jbrsdk_jcef-25.0.4.1-linux-x64-b329.136.tar.gz"
local JETBRAINS_DIGEST = "173f2b8b581c914e1bd1de543f4150f54d3b768d539eef4510baf92489e80924"
    .. "d6e061ccc35089240ae71742adfff8dba4fd9ac581eda209ce396986e91eb526"
local KONA = "TencentKona-25.0.4.b1-jdk_linux-x86_64.tar.gz"
local KONA_DIGEST = "78849dd1f67c2159085dcd42e307e76a"
local SAP = "sapmachine-jdk-11.0.2_windows-x64_bin.zip"
local SAP_DIGEST = "9cd3567fa6d61d46d8f83ba637feef4fe3deca7d17e0932c7f0c59128477f1d3"
local SAP_LINUX = "sapmachine-jdk-27.0.1.0.3_linux-x64_bin.tar.gz"
local SAP_LINUX_DIGEST = "f76343142101b3b5e7cfecf664b55feeac4c9ce6df464f339ae27cda8234f637"

-- What a file is called, as a list of names: one name stands for itself.
local function called(name)
    if type(name) == "string" then
        return { name }
    end
    return name
end

-- Checks that content gives digest for the file called name.
local function parses(content, kind, name, digest)
    local got, reason = checksum.parse(content, kind, called(name))
    assert(got == digest, ("%q: expected %s, got %s (%s)"):format(content, digest, tostring(got), tostring(reason)))
    cases = cases + 1
end

-- Checks that content gives no digest, and that the reason, which ends a
-- sentence about the file, is the one given.
local function rejects(content, kind, name, reason)
    local got, why = checksum.parse(content, kind, called(name))
    assert(got == nil, ("%q: expected no digest, got %s"):format(content, tostring(got)))
    assert(why == reason, ("%q: expected %q, got %q"):format(content, reason, tostring(why)))
    cases = cases + 1
end

-- A digest on its own: GraalVM Community's .sha256 file, with the line end
-- that a shell leaves, without it, and the other ways files come.
parses(GRAALCE_DIGEST .. "\n", "sha256", GRAALCE, GRAALCE_DIGEST)
parses(GRAALCE_DIGEST, "sha256", GRAALCE, GRAALCE_DIGEST)
parses(GRAALCE_DIGEST .. "\r\n", "sha256", GRAALCE, GRAALCE_DIGEST)
parses("\239\187\191" .. GRAALCE_DIGEST .. "\r\n", "sha256", GRAALCE, GRAALCE_DIGEST)
parses("  " .. GRAALCE_DIGEST .. " \t\n\n", "sha256", GRAALCE, GRAALCE_DIGEST)
-- vfox compares lower case hexadecimal.
parses(GRAALCE_DIGEST:upper(), "sha256", GRAALCE, GRAALCE_DIGEST)
-- A bare digest is the file's whatever the name asked for.
parses(GRAALCE_DIGEST, "sha256", nil, GRAALCE_DIGEST)

-- A digest with the name of its file, as sha256sum writes it: Microsoft's has
-- no line end, JetBrains' is a SHA-512, SAP's has one space and, for the
-- Windows builds, a * for a binary file.
parses(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", MICROSOFT, MICROSOFT_DIGEST)
parses(JETBRAINS_DIGEST .. "  " .. JETBRAINS .. "\n", "sha512", JETBRAINS, JETBRAINS_DIGEST)
parses(SAP_LINUX_DIGEST .. " " .. SAP_LINUX .. "\n", "sha256", SAP_LINUX, SAP_LINUX_DIGEST)
parses(SAP_DIGEST .. " *" .. SAP .. "\n", "sha256", SAP, SAP_DIGEST)
parses(MICROSOFT_DIGEST .. "\t" .. MICROSOFT .. "\r\n", "sha256", MICROSOFT, MICROSOFT_DIGEST)
-- The name may carry the directory it was listed from, on either system.
parses(MICROSOFT_DIGEST .. "  ./" .. MICROSOFT .. "\n", "sha256", MICROSOFT, MICROSOFT_DIGEST)
parses(MICROSOFT_DIGEST .. "  dist/" .. MICROSOFT .. "\n", "sha256", MICROSOFT, MICROSOFT_DIGEST)
parses(MICROSOFT_DIGEST .. "  dist\\" .. MICROSOFT .. "\n", "sha256", MICROSOFT, MICROSOFT_DIGEST)

-- BSD's form, as Tencent Kona's .md5 file is, and its SHA-2 counterpart.
parses("MD5 (" .. KONA .. ") = " .. KONA_DIGEST .. "\n", "md5", KONA, KONA_DIGEST)
parses("SHA256 (" .. GRAALCE .. ") = " .. GRAALCE_DIGEST, "sha256", GRAALCE, GRAALCE_DIGEST)
parses("SHA-256 (" .. GRAALCE .. ") = " .. GRAALCE_DIGEST, "sha256", GRAALCE, GRAALCE_DIGEST)

-- A file that lists several takes the entry of the package, whichever line it
-- is on, and passes over lines that are none, such as the armor of a signed one.
local listing = table.concat({
    "-----BEGIN PGP SIGNED MESSAGE-----",
    "Hash: SHA256",
    "",
    SAP_DIGEST .. "  " .. SAP,
    MICROSOFT_DIGEST .. "  " .. MICROSOFT,
    SAP_LINUX_DIGEST .. "  " .. SAP_LINUX,
    "-----BEGIN PGP SIGNATURE-----",
}, "\n")
parses(listing, "sha256", MICROSOFT, MICROSOFT_DIGEST)
parses(listing, "sha256", SAP_LINUX, SAP_LINUX_DIGEST)
parses(listing, "sha256", SAP, SAP_DIGEST)
-- The same entry twice is one.
parses(SAP_DIGEST .. "  " .. SAP .. "\n" .. SAP_DIGEST:upper() .. " *" .. SAP .. "\n", "sha256", SAP, SAP_DIGEST)
-- A file may be called by either of two names in a listing: the one Foojay
-- gives, and the last part of the address it is downloaded from.
parses(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", { "other.tar.gz", MICROSOFT }, MICROSOFT_DIGEST)
parses(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", { MICROSOFT, "other.tar.gz" }, MICROSOFT_DIGEST)

-- Only the digests of the algorithm count, so a file that lists a SHA-1 next to
-- a SHA-256 of the same file, or an MD5 above the digest it has no name for, is
-- read for the one Foojay names.
local SHA1_DIGEST = "b0c9756cc59a2a0af415387c808cf550b4181471"
parses(
    SHA1_DIGEST .. "  " .. MICROSOFT .. "\n" .. MICROSOFT_DIGEST .. "  " .. MICROSOFT .. "\n",
    "sha256",
    MICROSOFT,
    MICROSOFT_DIGEST
)
parses(
    MICROSOFT_DIGEST .. "  " .. MICROSOFT .. "\n" .. SHA1_DIGEST .. "  " .. MICROSOFT .. "\n",
    "sha1",
    MICROSOFT,
    SHA1_DIGEST
)
parses(KONA_DIGEST .. "\n" .. GRAALCE_DIGEST .. "\n", "sha256", GRAALCE, GRAALCE_DIGEST)

-- A digest of another file would fail an install that is fine, so a file that
-- names others only, or leaves the choice open, gives none. Microsoft's file
-- for the EA build of 11.0.14 for macOS names the GA build.
rejects(
    listing,
    "sha256",
    "microsoft-jdk-21.0.8-linux-x64.tar.gz",
    "no digest for microsoft-jdk-21.0.8-linux-x64.tar.gz"
)
rejects(
    "9dd0198ecddb04d9d04a58dd40d4499918300538a81a7504496848abb601a9c7  microsoft-jdk-11.0.14.9.1-macOS-aarch64.tar.gz",
    "sha256",
    "microsoft-jdk-11.0.14.9.1-ea-macOS-aarch64.tar.gz",
    "no digest for microsoft-jdk-11.0.14.9.1-ea-macOS-aarch64.tar.gz"
)
-- Nothing to tell the file by.
rejects(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", nil, "no digest for the file")
rejects(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", {}, "no digest for the file")
rejects(MICROSOFT_DIGEST .. "  " .. MICROSOFT, "sha256", "", "no digest for ")
rejects(GRAALCE_DIGEST .. "\n" .. SAP_DIGEST .. "\n", "sha256", GRAALCE, "2 digests and no names to tell them apart")
rejects(
    SAP_DIGEST .. "  " .. SAP .. "\n" .. GRAALCE_DIGEST .. "  " .. SAP .. "\n",
    "sha256",
    SAP,
    "different digests for " .. SAP
)

-- What is no digest of the algorithm is none: another algorithm's, such as the
-- 32 digits of an MD5 where Foojay says SHA-256, or a digest cut short.
rejects(KONA_DIGEST, "sha256", GRAALCE, "a digest of 32 digits, where sha256 has 64")
rejects(GRAALCE_DIGEST, "md5", GRAALCE, "a digest of 64 digits, where md5 has 32")
rejects(GRAALCE_DIGEST:sub(1, 63), "sha256", GRAALCE, "a digest of 63 digits, where sha256 has 64")
rejects(JETBRAINS_DIGEST, "sha1", JETBRAINS, "a digest of 128 digits, where sha1 has 40")
rejects(KONA_DIGEST .. "  " .. GRAALCE, "sha256", GRAALCE, "a digest of 32 digits, where sha256 has 64")
-- vfox verifies four algorithms only.
rejects(GRAALCE_DIGEST, "sha3_256", GRAALCE, "a sha3_256 digest, which vfox cannot verify")
rejects(GRAALCE_DIGEST, nil, GRAALCE, "a nil digest, which vfox cannot verify")

-- What is no checksum file at all: a page where a mirror or a portal answers
-- 200, an empty answer, a signature.
rejects("", "sha256", GRAALCE, "no digest")
rejects("\n\n", "sha256", GRAALCE, "no digest")
rejects("<html><body>Blocked</body></html>", "sha256", GRAALCE, "no digest")
rejects("<!DOCTYPE html>\n<title>404</title>\nNot found\n", "sha256", GRAALCE, "no digest")
rejects(
    "-----BEGIN PGP SIGNATURE-----\n\niQEzBAABCAAdFiEE\n-----END PGP SIGNATURE-----\n",
    "sha256",
    GRAALCE,
    "no digest"
)
rejects("not a digest", "sha256", GRAALCE, "no digest")

-- Foojay's record of a package, as the plugin reads it from links.pkg_info_uri.
local URI = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-25.0.2/" .. GRAALCE .. ".sha256"
local function record(fields)
    local result = { filename = GRAALCE, checksum_type = "sha256", checksum = "", checksum_uri = "" }
    for key, value in pairs(fields) do
        result[key] = value
    end
    return result
end

-- What the plugin fetches, and from where: files maps an address to the
-- contents, and any other address answers 404.
local files = {}
local fetched = {}
local function fetch(uri)
    table.insert(fetched, uri)
    if files[uri] then
        return files[uri]
    end
    return nil, "status_code => 404"
end

-- Checks the checksum that lookup finds, and the addresses it fetched.
local function finds(info, kind, digest, expected_fetched)
    fetched = {}
    local found, reason = checksum.lookup(info, fetch)
    assert(
        found and found.type == kind and found.digest == digest,
        ("%s: expected %s %s, got %s (%s)"):format(
            tostring(info.filename),
            kind,
            digest,
            found and found.type .. " " .. found.digest or "none",
            tostring(reason)
        )
    )
    assert(reason == nil, "a checksum comes with no reason: " .. tostring(reason))
    assert(
        table.concat(fetched, " ") == table.concat(expected_fetched, " "),
        "fetched " .. table.concat(fetched, " ") .. ", expected " .. table.concat(expected_fetched, " ")
    )
    cases = cases + 1
end

-- Checks that lookup finds none, for the reason given (nil for no reason), and
-- the addresses it fetched.
local function misses(info, reason, expected_fetched)
    fetched = {}
    local found, why = checksum.lookup(info, fetch)
    assert(found == nil, "expected no checksum, got " .. (found and found.type .. " " .. found.digest or ""))
    assert(
        why == reason,
        ("%s: expected reason %q, got %q"):format(tostring(info.filename), tostring(reason), tostring(why))
    )
    assert(
        table.concat(fetched, " ") == table.concat(expected_fetched, " "),
        "fetched " .. table.concat(fetched, " ") .. ", expected " .. table.concat(expected_fetched, " ")
    )
    cases = cases + 1
end

-- The digest in Foojay's record is the one to take, and nothing is fetched for
-- it: Temurin's records carry theirs, GraalVM Community's newest too.
finds(record({ checksum = GRAALCE_DIGEST, checksum_uri = URI }), "sha256", GRAALCE_DIGEST, {})
finds(record({ checksum = GRAALCE_DIGEST:upper() }), "sha256", GRAALCE_DIGEST, {})
finds(record({ checksum = " " .. GRAALCE_DIGEST .. "\n" }), "sha256", GRAALCE_DIGEST, {})
finds(record({ checksum = KONA_DIGEST, checksum_type = "md5" }), "md5", KONA_DIGEST, {})
finds(
    record({ checksum = "b0c9756cc59a2a0af415387c808cf550b4181471", checksum_type = "sha1" }),
    "sha1",
    "b0c9756cc59a2a0af415387c808cf550b4181471",
    {}
)
-- Foojay writes the algorithm in lower case; the key vfox takes is lower case.
finds(record({ checksum = GRAALCE_DIGEST, checksum_type = "SHA256" }), "sha256", GRAALCE_DIGEST, {})

-- Where the record has the address of a file only, the file is fetched once.
files[URI] = GRAALCE_DIGEST .. "\n"
finds(record({ checksum_uri = URI }), "sha256", GRAALCE_DIGEST, { URI })
files[URI] = "MD5 (" .. GRAALCE .. ") = " .. KONA_DIGEST .. "\n"
finds(record({ checksum_uri = URI, checksum_type = "md5" }), "md5", KONA_DIGEST, { URI })
files[URI] = JETBRAINS_DIGEST .. "  " .. GRAALCE .. "\n"
finds(record({ checksum_uri = URI, checksum_type = "sha512" }), "sha512", JETBRAINS_DIGEST, { URI })
-- A digest in the record that is no digest of the algorithm gives way to the file.
files[URI] = GRAALCE_DIGEST .. "\n"
finds(record({ checksum = KONA_DIGEST, checksum_uri = URI }), "sha256", GRAALCE_DIGEST, { URI })

-- A listing may call the file by the last part of the address it is downloaded
-- from, which vfox names it after, and not by Foojay's name; %2B is a +.
local DOWNLOADS = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-25.0.2/"
files[URI] = GRAALCE_DIGEST .. "  " .. GRAALCE .. "\n"
finds(
    record({ filename = "other.tar.gz", checksum_uri = URI, direct_download_uri = DOWNLOADS .. GRAALCE }),
    "sha256",
    GRAALCE_DIGEST,
    { URI }
)
finds(
    record({ filename = false, checksum_uri = URI, direct_download_uri = DOWNLOADS .. GRAALCE .. "?a=b#c" }),
    "sha256",
    GRAALCE_DIGEST,
    { URI }
)
files[URI] = GRAALCE_DIGEST .. "  graalvm+community.tar.gz\n"
finds(
    record({ filename = false, checksum_uri = URI, direct_download_uri = DOWNLOADS .. "graalvm%2Bcommunity.tar.gz" }),
    "sha256",
    GRAALCE_DIGEST,
    { URI }
)
misses(
    record({ filename = false, checksum_uri = URI, direct_download_uri = DOWNLOADS .. "graalvm-community.tar.gz" }),
    URI .. " has no digest for graalvm-community.tar.gz",
    { URI }
)
misses(record({ filename = false, checksum_uri = URI }), URI .. " has no digest for the file", { URI })
files[URI] = GRAALCE_DIGEST .. "\n"

-- Without Foojay knowing a checksum there is nothing to say: no algorithm, or
-- none, and neither a digest nor an address.
files[URI] = GRAALCE_DIGEST .. "\n"
misses(record({ checksum_type = "", checksum = GRAALCE_DIGEST, checksum_uri = URI }), nil, {})
misses(record({ checksum_type = "none", checksum_uri = URI }), nil, {})
misses({ filename = GRAALCE }, nil, {})
misses(record({ checksum_type = false, checksum = GRAALCE_DIGEST }), nil, {})
misses(record({}), nil, {})
misses(record({ checksum = " \n", checksum_uri = " " }), nil, {})

-- Where it knows one that cannot be used, the reason is given and the install
-- goes on without it. Nothing is fetched for an algorithm vfox cannot verify.
misses(record({ checksum_type = "sha3_256", checksum_uri = URI }), "vfox cannot verify a sha3_256 checksum", {})
files[URI] = nil
misses(record({ checksum_uri = URI }), "failed to fetch " .. URI .. ": status_code => 404", { URI })
files[URI] = "<html>Blocked</html>"
misses(record({ checksum_uri = URI }), URI .. " has no digest", { URI })
files[URI] = MICROSOFT_DIGEST .. "  " .. MICROSOFT .. "\n"
misses(record({ checksum_uri = URI }), URI .. " has no digest for " .. GRAALCE, { URI })
files[URI] = KONA_DIGEST .. "\n"
misses(record({ checksum_uri = URI }), URI .. " has a digest of 32 digits, where sha256 has 64", { URI })
misses(
    record({ checksum = KONA_DIGEST }),
    "the checksum in Foojay's record has a digest of 32 digits, where sha256 has 64",
    {}
)
-- A digest in the record that cannot be used does not hide a file that can.
files[URI] = "<html>Blocked</html>"
misses(record({ checksum = KONA_DIGEST, checksum_uri = URI }), URI .. " has no digest", { URI })

print("PASS: " .. cases .. " checksum cases")
