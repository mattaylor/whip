# Package

version       = "0.1.0"
author        = "mtaylor"
description   = ""
license       = "MIT"

skipDirs = @["tests"]
# Dependencies

requires "nim >= 0.19.0", "whip", "asyncpg", "emerald"

task test, "run tests": exec "nim c -r --threads=on ./whip.nim"
task bench, "run bench": exec "./bench.sh -c"
