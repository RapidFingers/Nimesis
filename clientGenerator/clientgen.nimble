# Package

version       = "0.1.0"
author        = "Grabli66"
description   = "Client generator for nimesis database"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.0", "websocket", "variant"
srcDir = "./src"
binDir = "../build"
bin = @["clientgen.exe"]