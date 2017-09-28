# Package

version       = "0.1.0"
author        = "Grabli66"
description   = "Master data managment database"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.0", "websocket", "variant"
srcDir = "./src"
binDir = "../build"
bin = @["server.exe"]