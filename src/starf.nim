import starintel_doc
import json
import parsecsv
import asyncdispatch
import mycouch
import starfpkg/parsing

proc parseCsvRow(config: MetaConfig, csv: var CsvParser): seq[JsonNode] =
  var
    docs: seq[JsonNode]
  if config.person.enabled:
    docs.add(config.parsePerson(csv).dump)
  if config.address.enabled:
    docs.add(config.parseAddress(csv).dump)
  if config.org.enabled:
    docs.add(config.parseOrg(csv).dump)
  if config.email.enabled:
    docs.add(config.parseEmail(csv).dump)
  result = config.link(docs)


proc parseJsonLine(config: MetaConfig, line: JsonNode): seq[JsonNode] =
  var docs: seq[JsonNode]
  if config.person.enabled:
    docs.add(config.parsePerson(line).dump)
  if config.address.enabled:
    docs.add(config.parseAddress(line).dump)
  if config.org.enabled:
    docs.add(config.parseOrg(line).dump)
  if config.email.enabled:
    docs.add(config.parseEmail(line).dump)
  result = config.link(docs)

proc genConfig(): JsonNode =
  let person = People(fname: "first_name", mname: "middle_name",
                      lname: "last_name", race: "race", gender: "male",
                      dob: "dob", bio: "bio", region: "region", enabled: true)
  let org = Orgs(name: "org_name", orgType: "org-type", reg: "reg", website: "website",
                 country: "United States", defaultOrgType: "corp", enabled: true)
  let emails = Emails(email: "email", emailUsername: "email_username", emailDomain: "email_domain", emailPassword: "password", enabled: false)
  let address = Address(street: "street", street2: "street2", country: "country", state: "state", postal: "postal",
                        city: "city", lat: "lat", long: "long", alt: "alt", enabled: true)
  let mapping = LinkMap(dtype: "person", targetType: "org", relation: Relations.member)
  var meta = MetaData(dataset: "star-intel", dateAdded: "date", dateUpdated: "date")
  meta.mapping.add(mapping)
  result = %*MetaConfig(person: person, org: org, email: emails, metadata: meta, address: address)
proc injestCsv*(config: MetaConfig, star: AsyncCouchDBClient, path: string, database: string = "star-intel") {.async.} =
  var
    p: CsvParser
    docs: seq[JsonNode]
  p.open(path)
  p.readHeaderRow
  while p.readRow():
    try:
      docs.add(config.parseCsvRow(p))
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
  var docs: seq[JsonNode]
  let f = open(path, fmRead)
  for line in f.lines:
    try:
      docs.add(config.parseJsonLine(line.parseJson))
      if docs.len == 1000:
        discard await star.bulkDocs(database, %docs)
        docs = @[]
      if docs.len != 0:
        discard await star.bulkDocs(database, %docs)
    except KeyError:
      discard
proc convertJson*(config: MetaConfig, input: string, output = "") =
  ## Read a File and output to a spec complient document
  let f = open(input, fmRead)
  var o: File
  o = open(output, fmAppend)
  for line in f.lines:
    try:
      let docs = config.parseJsonLine(line.parseJson)
      for doc in docs:
        o.writeLine(doc)
    except KeyError:
      discard
proc convertCsv*(config: MetaConfig, input: string, output="") =
  var
    p: CsvParser
    o: File
  p.open(input)
  o = open(output, fmAppend)
  p.readHeaderRow
  while p.readRow():
    try:
      let docs = config.parseCsvRow(p)
      for doc in docs:
        o.writeLine(doc)
    except KeyError:
      discard
    except CsvError:
      discard


proc main(config = "config.json", mode="json", href="http:127.0.0.1", database="star-intel", couchPort=5489, upload=false, username = "", pass = "", output = "", input = "") =
  var star = newAsyncCouchDBClient(href, couchPort)
  case mode:
    of "json":
      let meta = readConfig(config)
      if upload == true:
        discard waitFor star.cookieAuth(username, pass)
        waitFor meta.injestJson(star, input, database)
      else:
        meta.convertJson(input, output)
    of "csv":
      let meta = readConfig(config)
      i upload == true:
        discard waitFor star.cookieAuth(username, pass)
        waitFor meta.injestCsv(star, input, database)
      else:
        meta.convertCsv(input, output)
    of "gen-config":
      let defaultConfig = %*MetaConfig()
      let o = open(config, fmWrite)
      defer: o.close()
      o.write(genConfig().pretty())
    else:
      echo "Unknown mode"
import cligen; dispatch main
