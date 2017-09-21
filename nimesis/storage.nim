import
    tables,
    streams,
    asyncdispatch,
    asyncfile,
    producer,
    dataLogger,
    database

#############################################################################################
# Workspace of storage
type Workspace = ref object
    classes : TableRef[BiggestUInt, Class]                    # All classes
    instances : TableRef[BiggestUInt, Instance]               # All instances

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()
    result.classes = newTable[BiggestUInt, Class]()
    result.instances = newTable[BiggestUInt, Instance]()

#############################################################################################
# Private

proc placeToDatabase() : void =    
    # Place all log to database
    for record in dataLogger.allRecords():
        database.writeLogRecord(record)
    dataLogger.removeLog()
    echo "All log placed to database"

proc getClass(classTable : TableRef[BiggestUInt, DbClass], id : BiggestUInt) : Class =
    # Get class from class table with all parents
    let cls = classTable.getOrDefault(id)
    if cls.isNil: return nil
    result = producer.newClass(id, cls.name, getClass(classTable, cls.parentId))

proc loadFromDatabase() : void =
    # Load all from database to memory
    let classes = database.getAllClasses()
    for k, v in classes:
        workspace.classes[v.id] = getClass(classes, v.id)
    
    echo "All data loaded from database"

#############################################################################################
# Public interface

proc storeNewClass*(class : Class) : Future[void] {.async.} =
    # Store new class data
    var parentId = 0'u64
    if not class.parent.isNil:
        parentId = class.parent.id

    var record = dataLogger.AddClassRecord(
        id : class.id, 
        name : class.name, 
        parentId : parentId
    )
    await dataLogger.logNewClass(record)

    workspace.classes[class.id] = class

proc storeNewField*(field : Field) : Future[void] {.async.} =
    # Store new field data
    discard
    # var record = dataLogger.newAddFieldRecord(field.id, field.name, field.parent.id)
    # await dataLogger.logNewField(record)
    # field.parent

proc getClassById*(id : BiggestUInt) : Class = 
    # Get class by id
    result = workspace.classes.getOrDefault(id)

proc init*() : void =
    # Init storage
    echo "Initing storage"
    workspace = newWorkspace()
    dataLogger.init()
    database.init()
    placeToDatabase()
    loadFromDatabase()
    echo "Init storage complete"