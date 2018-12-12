import jester, json
{.checks: off, optimization: speed.}

const JSON_DATA = $(%*{"result": "hello world"})
const TEXT_DATA = "Hello World"
const JSON_TYPE = "application/json"
const TEXT_TYPE = "text/plain"

routes:
  get "/text": resp TEXT_DATA, TEXT_TYPE
  get "/json": resp JSON_DATA, JSON_TYPE
  get "/text/@name": resp "Hello " & @"name", TEXT_TYPE
  get "/json/@name": resp $(%*{"hello": @"name"}), JSON_TYPE

#runForever()