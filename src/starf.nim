import starintel_doc
import jsony, json
import parsecsv
import asyncdispatch
import mycouch
proc injestCsv*(config: MetaConfig, star: AsyncCouchDBClient, path: string, database: string = "star-intel") {.async.} =
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
        discard await star.bulkDocs(database, %*docs)
        docs = @[]
      if docs.len != 0:
        discard await star.bulkDocs(database, %*docs)
    except KeyError:
      discard
    except CsvError:
      discard
proc injestJson*(config: MetaConfig, star: AsyncCouchDBClient, path: string, database: string = "star-intel") {.async.} =
  var
    docs: seq[JsonNode]
    jdoc: JsonNode
  let f = open(path, fmRead)
  for line in f.lines:
    try:
      var person = config.parsePerson(line.fromJson)
      person.makeUUID
      jdoc = %* person
      jdoc["_id"] = jdoc["id"]
      docs.add(jdoc)
      jdoc = %*{}
      if docs.len == 1000:
        let l = await star.bulkDocs(database, %docs)
        when defined(debug):
          echo $l
          echo %*docs
        docs = @[]
      if docs.len != 0:
        let l = await star.bulkDocs(database, %docs)
        when defined(debug):
          echo $l
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
      var jdoc = %person
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
      var jdoc = %person
      jdoc["_id"] = jdoc["id"]

      o.writeLine(jdoc)
      jdoc = %*{}
    except KeyError:
      discard
    except CsvError:
      discard

proc main(config = "config.json", mode="json", href="http:127.0.0.1", database="star-intel", couchPort=5489, upload=false, username = "", pass = "", output = "", input: string) =
  echo 1
  var star = newAsyncCouchDBClient(href, couchPort)
  let meta = readConfig(config)
  case mode:
    of "json":
      if upload == true:
        discard waitFor star.cookieAuth(username, pass)
        waitFor meta.injestJson(star, input, database)
      else:
        meta.convertJson(input, output)
    of "csv":
      if upload == true:
        discard waitFor star.cookieAuth(username, pass)
        waitFor meta.injestCsv(star, input, database)
      else:
        meta.convertCsv(input, output)

import cligen; dispatch main
