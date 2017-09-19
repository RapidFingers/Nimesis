import
    asyncdispatch,
    dataLogger,
    db_sqlite

const DATABASE_FILE_NAME = "database.dat"

#############################################################################################
# Workspace of database worker
type Workspace = ref object

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

#############################################################################################
# Public interface

proc writeLogRecord*(record : LogRecord) : void =
    # Write log record to database
    echo record.id

proc init*() : void =
    # Init database worker
    workspace = newWorkspace()