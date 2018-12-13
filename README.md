# WHIP

WHIP is a high performance web application server based on the excellent https://github.com/dom96/httpbeast and routing provided by https://github.com/kedean/nest with some additonal optimizations. 

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

As fast as Httpbeast for simple routes and 2-3x faster than Jester for complex routing.

But not as fast as fastrouter.

Very unscientific benchmarks...

Framework     | Lang | `/text/{name}`| `/json/{name}`| `/text`      
--------------|------|---------------|---------------|--------------      
__Whip__      | Nim  | 66.2k (0.15)  | 56.4k (0.17)   | 70.0k (0.14) 
__HttpBeast__ | Nim  | N/A           | N/A           | 68.2k (0.14) 
__Jester__    | Nim  | 16.2k (0.59)  | 15.6k (0.63)  | 56.7k (0.17) 
__Mofuw__     | Nim  | 8.71k (1.14)  | 8.13k (1.23)  | 9.13  (1.23) 
__GinGonic__  | Go   | 58.4k (0.14)  | 57.8k (0.15)  | 57.5k (0.15) 
__FastRouter__| Go   | 89.5k (0.09)  | N/A           | 90.3k (0.09) 

Total Reqs/Sec (Mean latencies in ms) taken from the best of 3 `wrk` runs using 2 threads and 10 connections for 10 secs 
For latest results see [[results.txt]]

To run ..

```bash
./bench.sh -c
``` 

## Its WIP 

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
