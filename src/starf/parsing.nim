import starintel_doc
import json
import parsecsv
import times
import strutils
type
  People* = object
    ## Configuration for json data holding data about people
    ## Fields are used to hold the name of the field
    fname*: string
    lname*: string
    mname*: string
    # if you only have a name field
    name*: string
    email*: string
    region*: string
    phone*: string # TODO
    phoneArray*: string # TODO
    bio*: string
    socialMediaArray*: string # TODO
    socialMedia*: string # TODO
    dob*: string # TODO
    gender*: string
    race*: string

  Orgs* = object
    ## Configuration for json data holding organization data
    name*: string # field holding name of org
    orgType*: string # field holding type of org NGO, corp, Government, ect
    reg*: string # registration number field
    bio*: string # About/bio page field
    website*: string
    country*: string
    defaultOrgType*: string # default org type
  Emails* =  object
    email*: string
    ## If you have the email username, domain and password
    emailUsername*: string
    emailDomain*: string
    emailPassword*: string
  Address* =  object
    ## Configuration for json data holding address data
    street*: string
    city*: string
    state*: string
    postal*: string
    street2*: string
    country*: string
    lat*: string
    long*: string
    alt*: string
  Metadata* =  object
    ## Not to Be confused with MetaConfig, this is the object holding metadata like dates and dataset info
    dateAdded*: string
    dateUpdated*: string
    dataset*: string
  MetaConfig* =  object
    ## Meta config holding all configrations for import jobs
    people*: People
    org*: Orgs
    address*: Address
    email*: Emails
    metadata*: Metadata

proc readConfig*(path: string): MetaConfig =
  ## Read a Json config that defines the mapping between fields
  var meta = MetaConfig()
  let f = open(path, fmRead)
  defer: f.close
  let jconfig = f.readAll.parseJson
  meta.metadata = jconfig["meta"].to(Metadata)
  meta.people = jconfig["people"].to(People)
  meta.org = jconfig["orgs"].to(Orgs)
  meta.address = jconfig["address"].to(Address)
  result = meta


proc nowUnix*(): int64 =
  result = now().toTime().toUnix()

proc parsePerson*(config: MetaConfig, line: JsonNode): BookerPerson =
  ## Parses a json line taking a MetaConfig object maping the fields from the people field.
  ##
  let defaultTime = nowUnix()
  var person = BookerPerson(dtype: "person", dataset: config.metadata.dataset)
  person.fname = line{config.people.fname}.getStr("")
  person.lname = line{config.people.lname}.getStr("")
  person.mname = line{config.people.mname}.getStr("")
  person.bio = line{config.people.bio}.getStr("")
  person.region = line{config.people.region}.getStr("")
  person.dob = line{config.people.dob}.getStr("")
  person.gender = line{config.people.gender}.getStr("")
  person.race = line{config.people.race}.getStr("")
  person.date_added = line{config.metadata.dateAdded}.getBiggestInt(defaultTime)
  person.date_updated = line{config.metadata.dateUpdated}.getBiggestInt(defaultTime)
  result = person

proc parsePerson*(config: MetaConfig, csv: var CsvParser): BookerPerson =
  let defaultTime = nowUnix()
  var person = BookerPerson(dtype: "person", dataset: config.metadata.dataset)
  person.fname = csv.rowEntry(config.people.fname)
  person.mname = csv.rowEntry(config.people.mname)
  person.lname = csv.rowEntry(config.people.lname)
  if config.people.region.len == 0 :
    person.region = csv.rowEntry(config.people.region)
  if config.metadata.dateAdded.len != 0:
    person.date_added = csv.rowEntry(config.metadata.dateAdded).parseBiggestInt()
  else:
    person.date_added = defaultTime

  if config.metadata.dateUpdated.len != 0:
    person.date_updated = csv.rowEntry(config.metadata.dateUpdated).parseBiggestInt()
  else:
    person.date_updated = defaultTime
  result = person


proc parseOrg*(config: MetaConfig, line: JsonNode): BookerOrg =
  let defaultTime = nowUnix()
  var org = BookerOrg(dtype: "org", dataset: config.metadata.dataset)
  org.name = line{config.org.name}.getStr("")
  org.reg = line{config.org.reg}.getStr("")
  org.bio = line{config.org.bio}.getStr("")
  org.website = line{config.org.website}.getStr("")
  org.country = line{config.org.country}.getStr("")
  org.date_added = line{config.metadata.dateAdded}.getBiggestInt(defaultTime)
  org.date_updated = line{config.metadata.dateUpdated}.getBiggestInt(defaultTime)
  if config.org.orgType.len != 0:
    org.etype = line{config.org.orgType}.getStr("")
  else:
    org.etype = config.org.defaultOrgType
  result = org

proc parseOrg*(config: MetaConfig, csv: var CsvParser): BookerOrg =
  let defaultTime = nowUnix()
  var org = BookerOrg(dtype: "org", dataset: config.metadata.dataset)
  org.name = csv.rowEntry(config.org.name)
  if config.org.reg.len != 0:
    org.reg = csv.rowEntry(config.org.reg)
  if config.org.bio.len != 0:
    org.bio = csv.rowEntry(config.org.bio)
  if config.org.website.len != 0:
    org.website = csv.rowEntry(config.org.website)
  if config.org.country.len != 0:
    org.country = csv.rowEntry(config.org.country)


  if config.metadata.dateAdded.len != 0:
    org.date_added = csv.rowEntry(config.metadata.dateAdded).parseBiggestInt()
  else:
    org.date_added = defaultTime

  if config.metadata.dateUpdated.len != 0:
    org.date_updated = csv.rowEntry(config.metadata.dateUpdated).parseBiggestInt()
  else:
    org.date_updated = defaultTime

  if config.org.orgType.len != 0:
    org.etype = csv.rowEntry(config.org.orgType)
  else:
    org.etype = config.org.defaultOrgType
  result = org


proc parseEmail*(config: MetaConfig, line: JsonNode): BookerEmail =
  let defaultTime = nowUnix()
  var email = BookerEmail(dtype: "email", dataset: config.metadata.dataset)
  if config.email.email.len != 0:
    email = newEmail(line{config.email.email}.getStr(), line{config.email.emailPassword}.getStr(""))
  else:
    email.emailUsername = line{config.email.emailUsername}.getStr()
    email.emailDomain = line{config.email.emailDomain}.getStr()
    email.emailPassword = line{config.email.emailPassword}.getStr("")
  email.date_added = line{config.metadata.dateAdded}.getBiggestInt(defaultTime)
  email.date_updated = line{config.metadata.dateUpdated}.getBiggestInt(defaultTime)
  result = email

proc parseEmail*(config: MetaConfig, csv: var CsvParser): BookerEmail =
  let defaultTime = nowUnix()
  var email = BookerEmail(dtype: "email", dataset: config.metadata.dataset)
  if config.email.email.len != 0:
    let e = csv.rowEntry(config.email.email)
    email = e.newEmail()
    if config.email.emailPassword.len != 0:
       email.emailPassword = csv.rowEntry(config.email.emailPassword)
  else:
    email.emailUsername = csv.rowEntry(config.email.emailUsername)
    email.emailDomain = csv.rowEntry(config.email.emailDomain)
    if config.email.emailPassword.len != 0:
       email.emailPassword = csv.rowEntry(config.email.emailPassword)
  if config.metadata.dateAdded.len != 0:
    email.date_added = csv.rowEntry(config.metadata.dateAdded).parseBiggestInt()
  else:
    email.date_added = defaultTime

  if config.metadata.dateUpdated.len != 0:
    email.date_updated = csv.rowEntry(config.metadata.dateUpdated).parseBiggestInt()
  else:
    email.date_updated = defaultTime
  result = email



proc parseAddress*(config: MetaConfig, line: JsonNode): BookerAddress =
  var address: BookerAddress
  address.street = line{config.address.street}.getStr("")
  address.street2 = line{config.address.street2}.getStr("")
  address.city = line{config.address.city}.getStr("")
  address.postal = line{config.address.postal}.getStr("")
  address.state = line{config.address.state}.getStr("")
  address.country = line{config.address.country}.getStr("")
  address.lat = line{config.address.lat}.getFloat(0.0)
  address.long = line{config.address.long}.getFloat(0.0)
  address.alt = line{config.address.alt}.getFloat(0.0)
  result = address


proc parseAddress*(config: MetaConfig, csv: var CsvParser): BookerAddress =
  var address: BookerAddress
  address.street = csv.rowEntry(config.address.street)
  address.street2 = csv.rowEntry(config.address.street2)
  address.city = csv.rowEntry(config.address.city)
  address.postal = csv.rowEntry(config.address.postal)
  address.state = csv.rowEntry(config.address.state)
  address.country = csv.rowEntry(config.address.country)
  if config.address.lat.len != 0 or config.address.long.len != 0:
    address.lat = csv.rowEntry(config.address.lat).parseFloat()
    address.long = csv.rowEntry(config.address.long).parseFloat()
    address.alt = csv.rowEntry(config.address.alt).parseFloat()
  result = address
