import
    tables,
    streams,
    asyncdispatch,
    asyncfile,
    variant,
    producer,
    dataLogger,
    database

#############################################################################################
# Workspace of storage
type Workspace = ref object
    classes : TableRef[BiggestUInt, Class]                    # All classes
    instances : TableRef[BiggestUInt, Instance]               # All instances
    fields : TableRef[BiggestUInt, Field]                     # All fields

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()
    result.classes = newTable[BiggestUInt, Class]()
    result.instances = newTable[BiggestUInt, Instance]()
    result.fields = newTable[BiggestUInt, Field]()

#############################################################################################
# Private

# Forward declaration
proc getClassById*(id : BiggestUInt) : Class

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

    # Load all instances to memory

    # Load all fields to memory
    let fields = database.getAllFields()
    for f in fields:
        case f.parentType
        of database.CLASS_PARENT:
            let class = getClassById(f.parentId)
            let field = producer.newClassField(f.id, f.name, class)
            class.classFields.add(field)
        of database.INSTANCE_PARENT:
            discard
        else: 
            raise newException(Exception, "Unknown parent type")

    # Load values to memory, except blobs
    
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

proc storeNewInstance*(instance : Instance) : Future[void] {.async.} =
    # Store new instance data
    discard

proc storeNewField*(field : Field) : Future[void] {.async.} =
    # Store new class field data

    var record = dataLogger.AddFieldRecord(
        id : field.id,
        name : field.name,
        isClassField : true,
        parentId : field.parent.id
    )
    await dataLogger.logNewField(record)
    field.parent.classFields.add(field)
    workspace.fields[field.id] = field

proc getClassById*(id : BiggestUInt) : Class = 
    # Get class by id
    result = workspace.classes.getOrDefault(id)

proc geInstanceById*(id : BiggestUInt) : Instance =
    # Get instance by id
    result = workspace.instances.getOrDefault(id)

proc getFieldById*(id : BiggestUInt) : Field =
    # Get field by id
    result = workspace.fields.getOrDefault(id)

proc getFieldValue*(field : Field) : Value = 
    # Return field value of class
    result = field.parent.values.getOrDefault(field.id)

proc getFieldValue*(field : Field, instance : Instance) : Value =
    # Return field value of instance
    result = instance.values.getOrDefault(field.id)

proc setFieldValue*(field : Field, value : Variant) : void =
    # Set field value
    #dataLogger.logNewValue()
    #workspace.values[field.id].value = value
    discard

proc init*() : void =
    # Init storage
    echo "Initing storage"
    workspace = newWorkspace()
    dataLogger.init()
    database.init()
    placeToDatabase()
    loadFromDatabase()
    echo "Init storage complete"