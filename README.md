# whip


## Its Simple

```nim
import ../whip, sugar, json

let w = initWhip()
w.onGet "/json/{name}", (w:Wreq) => w.send(%*{ "name": w.path("name")})
w.onGet "/text/{name}", (w:Wreq) => w.send("hello " & w.path("name"))
w.start()
```

## Its Fast.
  
Route          | Whip                 | HttpBest  | Jester/HttpBest
---------------|----------------------|-----------|------------------
`/text/{name}` | 28k r/s, 0.36 ms | N/A           | 7.5k, 1.4 ms
`/json/{name}` | 23k r/s, 0.46 ms | N/A              | 6.4k, 1.5 ms
`/text`        | 48k r/s, 0.20 ms | 48k r/s, 0.20 ms | 33k r/s, 0.32 ms
`/json`        | 37k r/s, 0.27 ms | 38k r/s, 0.26 ms | 27k r/s, 0.37 ms

Total Reqs/Sec and Mean latencies taken from the best of 3 `wrk` runs using 2 threads and 10 connections for 10 secs 
eg 
```bash33
> wrk http://localhost:8000/text
```
