import starintel_doc
import jsony, json
import parsecsv
import starintel_couchdb
import asyncdispatch
import mycouch
proc injestCsv*(config: MetaConfig, star: AsyncStarintelDatabase, path: string) {.async.} =
  var
    p: CsvParser
    docs: seq[JsonNode]
    jdoc: JsonNode
  p.open(path)
  p.readHeaderRow
  while p.readRow():
    try:
      var person = config.parsePerson(p)
      person.makeUUID
      jdoc = %*person

      jdoc["_id"] = jdoc["id"]
      docs.add(jdoc)
      jdoc = %*{}
      if docs.len == 1000:
        discard await star.server.bulkDocs(star.database, %*docs)
        docs = @[]
      if docs.len != 0:
        discard await star.server.bulkDocs(star.database, %*docs)
    except KeyError:
      discard
    except CsvError:
      discard
proc injestJson*(config: MetaConfig, star: AsyncStarintelDatabase, path: string) {.async.} =
  var
    docs: seq[JsonNode]
    jdoc: JsonNode
  let f = open(path, fmRead)
  for line in f.lines:
    try:
      var person = config.parsePerson(line.fromJson)
      jdoc = %*person
      jdoc["_id"] = jdoc["id"]
      docs.add(jdoc)
      jdoc = %*{}
      if docs.len == 1000:
        discard await star.server.bulkDocs(star.database, %*docs)
        docs = @[]
      if docs.len != 0:
        discard await star.server.bulkDocs(star.database, %*docs)
    except KeyError:
      discard
proc convertJson*(config: MetaConfig, input: string, output = "") =
  ## Read a File and output to a spec complient document
  let f = open(input, fmRead)
  var o: File
  o = open(output, fmAppend)
  for line in f.lines:
    try:
      var person = config.parsePerson(line.fromJson)
      var jdoc = %*person
      jdoc["_id"] = jdoc["id"]

      o.writeLine(jdoc)
      jdoc = %*{}
    except KeyError:
      discard
proc convertCsv*(config: MetaConfig, input: string, output="") =
  var
    p: CsvParser
    docs: seq[JsonNode]
    jdoc: JsonNode
    o: File
  p.open(input)
  o = open(output, fmAppend)
  p.readHeaderRow
  while p.readRow():
    try:
      var person = config.parsePerson(p)
      var jdoc = %*person
      jdoc["_id"] = jdoc["id"]

      o.writeLine(jdoc)
      jdoc = %*{}
    except KeyError:
      discard
    except CsvError:
      discard

proc main(config = "config.json", mode="json", href="http:127.0.0.1", database="star-intel", couchPort=5489, upload=false, output = "", input: string) =
  echo 1
  var star = initStarIntel(href, database, couchPort)
  let meta = readConfig(config)
  case mode:
    of "json":
      if upload == true:
        waitFor meta.injestJson(star, input)
      else:
        meta.convertJson(input, output)
    of "csv":
      if upload == true:
        waitFor meta.injestCsv(star, input)
      else:
        meta.convertCsv(input, output)

import cligen; dispatch main
