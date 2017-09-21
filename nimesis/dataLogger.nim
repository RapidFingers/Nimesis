import
    os,
    asyncdispatch,
    asyncfile,
    streams

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
# Writer

type 
    Writer = ref object of RootObj
        stream : StringStream
        len : uint32

proc newWriter() : Writer =
    result = Writer()
    result.stream = newStringStream()
    result.len = 0

proc data(this : Writer) : string =
    # Return data
    this.stream.setPosition(0)
    result = this.stream.readStr(int (this.len))

proc writeUint64(this : Writer, value : uint64) : void =
    # Write uint64 without type    
    this.stream.write(uint64 value)
    this.len += 8

proc writeUint8(this : Writer, value : uint8) : void =
    # Write uint8
    this.stream.write(uint8 value)
    this.len += 1

proc writeInt32(this : Writer, value : int32) : void =
    # Write int32
    this.stream.write(int32 value)
    this.len += 4

proc writeFloat64(this : Writer, value : float64) : void =
    # Write float64
    this.stream.write(float64 value)
    this.len += 8

proc writeString(this : Writer, value : string) : void =
    # Write string
    this.stream.write(uint32 value.len)
    this.stream.write(value)
    this.len += uint32(value.len + 4)

#############################################################################################
# Reader
type
    Reader = ref object of RootObj
        file : AsyncFile

proc newReader(file : AsyncFile) : Reader =
    # Create new reader
    result = Reader()
    result.file = file

proc readString(this : Reader, len : uint32) : Future[string] {.async.} =
    # Read string
    result = await this.file.read(int len)

proc readUint8(this : Reader) : Future[uint8] {.async.} = 
    let str = await this.file.read(1)
    result = uint8 str[0]

proc readUint32(this : Reader) : Future[uint32] {.async.} = 
    # Read string
    let str = await this.file.read(4)
    result = ((uint8 str[0]) shl 24) + ((uint8 str[1]) shl 16) + ((uint8 str[2]) shl 8) + (uint8 str[0])

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

#############################################################################################
# LogRecord

type LogRecord* = ref object of RootObj
    id* : uint64

#############################################################################################
# AddClassRecord

# Add new class record
type AddClassRecord* = ref object of LogRecord    
    name* : string
    parentId* : uint64

#############################################################################################
# Workspace of data logger
type Workspace = ref object

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

#############################################################################################
# Private

proc processAddClass(data : Reader) : Future[AddClassRecord] {.async.} =
    # Process add class record
    result = AddClassRecord()
    result.id = await data.readUint64()    
    result.parentId = await data.readUint64()
    let len = await data.readUint32()
    result.name = await data.readString(len)

proc processRecord(reader : Reader) : Future[LogRecord] {.async.} = 
    # Process record
    let recType = await reader.readUint8()
    case recType
    of ADD_CLASS_COMMAND: return await processAddClass(reader)
    # of ADD_FIELD_COMMAND: return await processAddField(reader)
    # of SET_VALUE_COMMAND: return await processSetValue(reader)
    else: raise newException(Exception, "Wrong record")

#############################################################################################
# Public interface

# proc newAddFieldRecord*(id : uint64, name : string, parentId : uint64) : AddClassRecord =
#     # Create new AddClassRecord
#     result = AddClassRecord(id : id, name : name, parentId : parentId)

proc logNewClass*(record : AddClassRecord) : Future[void] {.async.} =
    # Log new class
    var file = openAsync(LOG_FILE_NAME, fmAppend)
    var writer = newWriter()
    writer.writeUint8(ADD_CLASS_COMMAND)
    writer.writeUint64(record.id)    
    writer.writeUint64(record.parentId)    
    writer.writeString(record.name)
    await file.write(writer.data)
    file.close()

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