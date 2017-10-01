import
    os,
    asyncdispatch,
    asyncfile,    
    streams,
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
# Reader
type
    Reader = ref object of RootObj
        file : AsyncFile

proc newReader(file : AsyncFile) : Reader =
    # Create new reader
    result = Reader()
    result.file = file

proc readBool(this : Reader) : Future[bool] {.async.} =
    # Read bool
    let str = await this.file.read(1)
    result = bool str[0]

proc readString(this : Reader, len : uint32) : Future[string] {.async.} =
    # Read string
    result = await this.file.read(int len)

proc readStringWithLen(this : Reader) : Future[string] {.async.} =
    # Read string
    let str = await this.file.read(1)
    let len = uint32(str[0])
    result = await this.readString(len)

proc readUint8(this : Reader) : Future[uint8] {.async.} = 
    let str = await this.file.read(1)
    result = uint8 str[0]

proc readUint32(this : Reader) : Future[uint32] {.async.} = 
    # Read string
    let str = await this.file.read(4)
    result = ((uint8 str[0]) shl 24) + ((uint8 str[1]) shl 16) + ((uint8 str[2]) shl 8) + (uint8 str[0])

proc readInt32(this : Reader) : Future[int32] {.async.} = 
    # Read int32
    result = int32(await this.readUint32())

proc readUint64(this : Reader) : Future[uint64] {.async.} = 
    # Read string
    let str = await this.file.read(8)
    result = (uint64(uint8 str[7]) shl 56) + 
             (uint64(uint8 str[6]) shl 48) + 
             (uint64(uint8 str[5]) shl 40) + 
             (uint64(uint8 str[4]) shl 32) + 
             (uint64(uint8 str[3]) shl 24) + 
             (uint64(uint8 str[2]) shl 16) + 
             (uint64(uint8 str[1]) shl 8) + 
             uint64(uint8 str[0])

proc readFloat64(this : Reader) : Future[float64] {.async.} =
    # Read float64
    let str = await this.file.read(8)
    result = cast[float64](str)

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

proc getWriter() : Writer =
    # Get writer to file
    if workspace.file.isNil:
        result.file = openAsync(LOG_FILE_NAME, fmAppend)
    result = newWriter(workspace.file)

proc processAddClass(data : Reader) : Future[AddClassRecord] {.async.} =
    # Process add class record
    result = AddClassRecord()
    result.id = await data.readUint64()
    result.parentId = await data.readUint64()
    result.name = await data.readStringWithLen()

proc processAddInstance(data : Reader) : Future[AddInstanceRecord] {.async.} =
    # Process add instance record
    result = AddInstanceRecord()
    result.id = await data.readUint64()
    result.classId = await data.readUint64()
    result.name = await data.readStringWithLen()

proc processAddField(data : Reader, isClassField : bool = true) : Future[AddFieldRecord] {.async.} =
    # Process add field record
    result = AddFieldRecord()
    result.id = await data.readUint64()
    result.classId = await data.readUint64()
    result.isClassField = isClassField
    result.name = await data.readStringWithLen()
    result.valueType = ValueType(await data.readUint8())

proc processSetValue(data : Reader, isClassField : bool = true) : Future[SetValueRecord] {.async.} =
    # Process set value record
    result = SetValueRecord()
    result.id = await data.readUint64()
    result.isClassField = await data.readBool()
    if not result.isClassField:
        result.instanceId = await data.readUint64()
    
    var value = Value(
        valueType : ValueType(await data.readUint8())
    )
    var variant : Variant
    
    case value.valueType
    of INT:
        variant = newVariant(await data.readInt32())
    of FLOAT:
        variant = newVariant(await data.readFloat64())
    of STRING:
        variant = newVariant(await data.readStringWithLen())
    else:
        raise newException(Exception, "Unknown type")

    value.value = variant
    result.value = value
    
proc processRecord(reader : Reader) : Future[LogRecord] {.async.} = 
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
    writer.writeUint8(ADD_CLASS_COMMAND)
    writer.writeUint64(record.id)    
    writer.writeUint64(record.parentId)    
    writer.writeString(record.name)
    await writer.flush()

proc logNewField*(record : AddFieldRecord) : Future[void] {.async.} =
    # Log new field
    var writer = getWriter()
    if record.isClassField:
        writer.writeUint8(ADD_CLASS_FIELD_COMMAND)
    else:
        writer.writeUint8(ADD_INSTANCE_FIELD_COMMAND)
    writer.writeUint64(record.id)
    writer.writeUint64(record.classId)
    writer.writeString(record.name)
    await writer.flush()

proc logNewInstance*(record : AddInstanceRecord) : Future[void] {.async.} =
    # Log new instance        
    var writer = getWriter()
    writer.writeUint8(ADD_INSTANCE_COMMAND)
    writer.writeUint64(record.id)
    writer.writeUint64(record.classId)    
    writer.writeString(record.name)
    await writer.flush()

proc logSetValue*(record : SetValueRecord) : Future[void] {.async.} =
    # Log set value
    var writer = getWriter()
    writer.writeUint8(SET_VALUE_COMMAND)
    writer.writeUint64(record.id)
    writer.writeBool(record.isClassField)
    if not record.isClassField:
        writer.writeUint64(record.instanceId)

    case record.value.valueType
    of INT:
        writer.writeInt32(record.value.value.get(int32))
    of FLOAT:
        writer.writeFloat64(record.value.value.get(float64))
    of STRING:
        let val = record.value.value.get(string)
        writer.writeUint8(uint8 val.len)
        writer.writeString(val)
    else:
        raise newException(Exception, "Unknown type")

    await writer.flush()

iterator allRecords*() : LogRecord = 
    # Iterate log file
    if os.existsFile(LOG_FILE_NAME):
        var file = openAsync(LOG_FILE_NAME, fmRead)
        let reader = newReader(file)

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