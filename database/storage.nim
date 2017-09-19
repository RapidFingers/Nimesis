import
    tables,
    streams,
    asyncdispatch,
    asyncfile,
    producer,
    dataLogger,
    databaseWorker

#############################################################################################
# Workspace of storage
type Workspace = ref object
    classes : TableRef[UniqueId, Class]                    # All classes
    instances : TableRef[UniqueId, Instance]               # All instances

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()
    result.classes = newTable[UniqueId, Class]()
    result.instances = newTable[UniqueId, Instance]()

#############################################################################################
# Private

proc placeToDatabase() : void =
    # Place all log to database
    for record in dataLogger.allRecords():
        databaseWorker.writeLogRecord(record)
    dataLogger.removeLog()

#############################################################################################
# Public interface

proc storeNewClass*(class : Class) : Future[void] {.async.} =
    # Store new class data
    var parentId = 0'u64
    if not class.parent.isNil:
        parentId = class.parent.id

    var record = dataLogger.newAddClassRecord(class.id, class.name, parentId)
    await dataLogger.logNewClass(record)

    workspace.classes[class.id] = class

proc init*() : void =
    # Init storage
    workspace = newWorkspace()
    dataLogger.init()
    databaseWorker.init()
    placeToDatabase()