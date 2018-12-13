import jester, json
{.checks: off, optimization: speed.}

const JSON_DATA = $(%*{"message": "Hello World!"})
const TEXT_DATA = "Hello World!"
const JSON_TYPE = "application/json"
const TEXT_TYPE = "text/plain"

settings:
  port = Port(8080)

routes:
  get "/text": resp TEXT_DATA, TEXT_TYPE
  get "/json": resp JSON_DATA, JSON_TYPE
  get "/text/@name": resp "Hello " & @"name", TEXT_TYPE
  get "/json/@name": resp $(%*{"Hello": @"name"}), JSON_TYPE

#runForever()