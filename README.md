# WHIP

WHIP is a high performance web application server based on the excellent https://github.com/dom96/httpbeast with routing based on https://github.com/kedean/nest and some extra optimizations thrown in for good measure. 

WHIP is still in development and is not recomended for production use. Much is still missing or untested but for basic api use cases however, the performance numbers look pretty good so far (see below). 

## Its Simple

```nim
import ../whip, sugar, json

let w = initWhip()
w.onGet "/json/{name}", (w:Wreq) => w.send(%*{ "name": w.path("name")})
w.onGet "/text/{name}", (w:Wreq) => w.send("hello " & w.path("name"))
w.start()
```

## Its Fast. 

Very unscientific benchmarks...

Framework     | Lang | `/text/{name}`| `/json/{name}`| `/text`      | `/json`
--------------|------|---------------|---------------|--------------|--------       
__Whip__      | Nim  | 49.8k (0.19)  | 45.2k (0.21)  | 70.0k (0.14) | 73.8k (0.13)
__HttpBeast__ | Nim  | N/A           | N/A           | 68.2k (0.14) | 72.8k (0.13)
__Jester__    | Nim  | 16.2k (0.59)  | 15.6k (0.63)  | 56.7k (0.17) | 50.0k (0.19)
__GinGonic__  | Go   | 58.4k (0.14)  | 57.8k (0.15)  | 57.5k (0.15) | 54.8k (0.15)

Total Reqs/Sec (Mean latencies in ms) taken from the best of 3 `wrk` runs using 2 threads and 10 connections for 10 secs 

eg 
```bash
> wrk http://localhost:8000/text
```

## Its a WIP 

Coming soon..

- middleware api
- websockets (mqtt) 
- swagger docs
- smarter headers 
- session storage (redis)
- sql db adapters (postgrest, graphql)
- smart caching
- static html serving
- html templates (jade)
- authentication (oauth, jwt)
- aws lambda interop