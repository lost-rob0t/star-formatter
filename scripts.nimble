# Package

version       = "0.1.0"
author        = "nsaspy"
description   = "Parse Data and format them into starintel documents, or upload to a database"
license       = "MIT"
srcDir        = "src"
bin           = @["starFormater"]


# Dependencies

requires "nim >= 1.6.8"
requires "jsony"
requires "starintel_doc"
requires "starintel_couchdb"
requires "cligen"
