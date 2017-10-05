import
    os,
    asyncdispatch,
    asyncfile,    
    streams,
    ../../shared/streamProducer,
    ../../shared/valuePacker    

const LOG_FILE_NAME = "change.log"

# Command to add class
const ADD_CLASS_COMMAND = 1
# Command to add instance
const ADD_INSTANCE_COMMAND = 2
# Command to add class field
const ADD_CLASS_FIELD_COMMAND = 3
# Command to add instance field
const ADD_INSTANCE_FIELD_COMMAND = 4
# Command to set field value
const SET_VALUE_COMMAND = 5

#############################################################################################
# Log records

type 
    # Base record
    LogRecord* = ref object of RootObj
        id* : uint64

    # Add new class record
    AddClassRecord* = ref object of LogRecord
        name* : string
        parentId* : uint64

    # Add new instance record
    AddInstanceRecord* = ref object of LogRecord
        name* : string
        classId* : uint64

    # Add new class record
    AddFieldRecord* = ref object of LogRecord
        classId* : uint64                       # Id of class
        name* : string                          # Name of field
        isClassField* : bool                    # Is field a class field
        valueType* : ValueType                  # Value type        

    # Set value record
    SetValueRecord* = ref object of LogRecord                
        case isClassField*: bool                # Is class field                    
        of false:
            instanceId* : uint64                # Parent of value class or instance
        else:
            discard
        value* : Value                           # Value type and value

#############################################################################################
# Workspace of data logger
type Workspace = ref object
    file : AsyncFile

var workspace {.threadvar.} : Workspace    

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()    

#############################################################################################
# Private

proc getWriter() : FileWriter =
    # Get writer to file
    if workspace.file.isNil:
        workspace.file = openAsync(LOG_FILE_NAME, fmAppend)
    result = newFileWriter(workspace.file)

proc processAddClass(data : FileReader) : Future[AddClassRecord] {.async.} =
    # Process add class record
    result = AddClassRecord()
    result.id = await data.readUint64()
    result.parentId = await data.readUint64()
    result.name = await data.readStringWithLen()

proc processAddInstance(data : FileReader) : Future[AddInstanceRecord] {.async.} =
    # Process add instance record
    result = AddInstanceRecord()
    result.id = await data.readUint64()
    result.classId = await data.readUint64()
    result.name = await data.readStringWithLen()

proc processAddField(data : FileReader, isClassField : bool = true) : Future[AddFieldRecord] {.async.} =
    # Process add field record
    result = AddFieldRecord()
    result.id = await data.readUint64()
    result.classId = await data.readUint64()
    result.isClassField = isClassField
    result.name = await data.readStringWithLen()
    result.valueType = ValueType(await data.readUint8())

proc processSetValue(data : FileReader, isClassField : bool = true) : Future[SetValueRecord] {.async.} =
    # Process set value record
    result = SetValueRecord()
    result.id = await data.readUint64()
    result.isClassField = await data.readBool()
    if not result.isClassField:
        result.instanceId = await data.readUint64()
    
    var value : Value

    let valueType = ValueType(await data.readUint8())
    case valueType
    of INT:
        value = box(await data.readInt32())
    of FLOAT:
        value = box(await data.readFloat64())
    of STRING:
        value = box(await data.readStringWithLen())
    else:
        raise newException(Exception, "Unknown type") 
        
    result.value = value
    
proc processRecord(reader : FileReader) : Future[LogRecord] {.async.} = 
    # Process record
    let recType = await reader.readUint8()
    case recType
    of ADD_CLASS_COMMAND: return await processAddClass(reader)
    of ADD_INSTANCE_COMMAND: return await processAddInstance(reader)
    of ADD_CLASS_FIELD_COMMAND: return await processAddField(reader)
    of ADD_INSTANCE_FIELD_COMMAND: return await processAddField(reader, true)
    of SET_VALUE_COMMAND: return await processSetValue(reader)
    else: raise newException(Exception, "Wrong record")

#############################################################################################
# Public interface

proc logNewClass*(record : AddClassRecord) : Future[void] {.async.} =
    # Log new class    
    var writer = getWriter()
    writer.addUint8(ADD_CLASS_COMMAND)
    writer.addUint64(record.id)    
    writer.addUint64(record.parentId)    
    writer.addStringWithLen(record.name)
    await writer.flush()

proc logNewField*(record : AddFieldRecord) : Future[void] {.async.} =
    # Log new field
    var writer = getWriter()
    if record.isClassField:
        writer.addUint8(ADD_CLASS_FIELD_COMMAND)
    else:
        writer.addUint8(ADD_INSTANCE_FIELD_COMMAND)
    writer.addUint64(record.id)
    writer.addUint64(record.classId)
    writer.addStringWithLen(record.name)
    await writer.flush()

proc logNewInstance*(record : AddInstanceRecord) : Future[void] {.async.} =
    # Log new instance        
    var writer = getWriter()
    writer.addUint8(ADD_INSTANCE_COMMAND)
    writer.addUint64(record.id)
    writer.addUint64(record.classId)
    writer.addStringWithLen(record.name)
    await writer.flush()

proc logSetValue*(record : SetValueRecord) : Future[void] {.async.} =
    # Log set value
    var writer = getWriter()
    writer.addUint8(SET_VALUE_COMMAND)
    writer.addUint64(record.id)
    writer.addBool(record.isClassField)
    if not record.isClassField:
        writer.addUint64(record.instanceId)

    if record.value of VInt:
        writer.addInt32(record.value.getInt())
    elif record.value of VFloat:
        writer.addFloat64(record.value.getFloat())
    elif record.value of VString:
        writer.addStringWithLen(record.value.getString())    
    else:
        raise newException(Exception, "Unknown type")

    await writer.flush()

iterator allRecords*() : LogRecord = 
    # Iterate log file
    if os.existsFile(LOG_FILE_NAME):
        var file = openAsync(LOG_FILE_NAME, fmRead)
        let reader = newFileReader(file)

        try:
            while true:
                yield waitFor processRecord(reader)
        except:        
            discard
            #echo getCurrentExceptionMsg()
        
        file.close()

proc removeLog*() : void =
    # Remove log file
    os.removeFile(LOG_FILE_NAME)

proc init*() : void =
    # Init data logger
    echo "Init data logger"
    workspace = newWorkspace()
    echo "Init data logger complete"