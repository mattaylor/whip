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

But not as fast as gingonic

V unscientific benchmarks...

Framework     | Lang | `/text/{name}`| `/json/{name}`| `/text`      | `/json`
--------------|------|---------------|---------------|--------------|--------       
__Whip__      | Nim  | 28.6k (0.36)  | 23.4k (0.46)  | 49.1k (0.20) | 49.5k (0.20)
__HttpBeast__ | Nim  | N/A           | N/A           | 50.1k (0.19) | 50.1k (0.19)
__Jester__    | Nim  | 7.54k (1.42)  | 6.45k (1.52)  | 35.0k (0.28) | 32.0k (0.31)
__GinGonic__  | Go   | 58.4k (0.14)  | 57.8k (0.15)  | 57.5k (0.15) | 54.8k (0.15)

Total Reqs/Sec (Mean latencies in ms) taken from the best of 3 `wrk` runs using 2 threads and 10 connections for 10 secs 

eg 
```bash
> wrk http://localhost:8000/text
```
