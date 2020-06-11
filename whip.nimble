# Package

version       = "0.1.0"
author        = "mtaylor"
description   = "Fast http server based on httpbeast and nest for high performance routing"
license       = "MIT"

skipDirs = @["tests", "empower"]
# Dependencies

#requires "packedjson", "nim >= 1.0.19.0", "nest", "httpbeast >= 0.2"
requires "packedjson", "nim", "nest", "httpbeast"

task test, "run tests": exec "nim c -r --threads=on ./whip.nim"
task bench, "run bench": exec "./bench.sh -c"
