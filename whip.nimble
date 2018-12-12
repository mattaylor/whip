# Package

version       = "0.1.0"
author        = "mtaylor"
description   = "Fast http server based on httpbeast and nest for high performance routing"
license       = "MIT"
srcDir        = "."


# Dependencies

requires "nim >= 0.19.0"
task test, "run tests": exec "nim c -r tests.nim"
