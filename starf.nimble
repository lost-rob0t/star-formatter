# Package

version       = "0.3.0"
author        = "nsaspy"
description   = "Parse Data and format them into starintel documents, or upload to a database"
license       = "MIT"
srcDir        = "src"
bin           = @["starf"]

# Dependencies

requires "nim >= 1.6.8"
requires "jsony"
requires "cligen"
requires "https://gitlab.nobodyhasthe.biz/nsaspy/starintel-doc-nim.git"
requires "mycouch"
requires "isaac"
requires "uuids"
task debug, "Build a debug build":
  exec("nim c -r --verbosity:0 --excessiveStackTrace:on  -o:./starfD ./src/starf.nim")
