# Only corest core type of all core types and constants 

import asyncdispatch

# Default server port
const DEFAULT_SERVER_PORT* = 9001
# Nimesis protocol name
const NIMESIS_PROTOCOL* = "nimesis"

proc fastWaitFor*[T](fut: Future[T]): T =
    ## **Blocks** the current thread until the specified future completes.
    while not fut.finished:
      poll(0)
  
    fut.read