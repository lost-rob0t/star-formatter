# Package

version       = "0.2.0"
author        = "nsaspy"
description   = "Parse Data and format them into starintel documents, or upload to a database"
license       = "MIT"
srcDir        = "src"
bin           = @["starf"]

# Dependencies

requires "nim >= 1.6.8"
requires "jsony"
requires "starintel_doc"
requires "cligen"
