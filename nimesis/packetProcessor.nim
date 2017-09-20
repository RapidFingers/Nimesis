import
    asyncdispatch,
    strutils,
    tables,
    times,    
    variant,
    ioDevice,    
    producer,
    storage

# Response codes
const OK_RESPONSE = 1
# Error response
const ERROR_RESPONSE = 2

# Add new class
const ADD_NEW_CLASS = 1
# Get class by id
const GET_CLASS_BY_ID = 2

#############################################################################################
# Process errors

# Class not found in storage
const CLASS_NOT_FOUND = 1

#############################################################################################
# Private

proc readStringWithLen(this : LimitedStream) : string = 
    # Read string from string with len
    let len = int this.readUint8()
    result = this.readString(len)

proc addStringWithLen(this : LimitedStream, value : string) : void = 
    # Add string with len    
    this.addUint8(uint8 value.len)
    this.addString(value)

template addOk(this : LimitedStream, packetId : uint8) : void = 
    # Add Ok to response
    this.addUint8(OK_RESPONSE)
    this.addUint8(packetId)

template addError(this : LimitedStream, packetId : uint8, errorCode : uint8) : void = 
    # Add Error to response
    this.addUint8(ERROR_RESPONSE)
    this.addUint8(packetId)
    this.addUint8(errorCode)

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

proc processAddNewClass(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
    # Process get class packet
    let name = packet.readStringWithLen()
    let parentId = packet.readUint64()
    let parent = storage.getClassById(parentId)
    let nclass = producer.newClass(name, parent)
    await storage.storeNewClass(nclass)
    response.addOk(ADD_NEW_CLASS)

proc processGetClassById(packet : LimitedStream, response : LimitedStream) : Future[void] {.async.} = 
    # Process get class by id
    let classId = packet.readUint64()
    echo classId
    let class = storage.getClassById(classId)
    if not class.isNil:
        response.addOk(GET_CLASS_BY_ID)
        response.addUint64(classId)
        response.addStringWithLen(class.name)
        if not class.parent.isNil:
            response.addUint64(class.parent.id)
        else:
            response.addUint64(0)
    else:
        response.addError(GET_CLASS_BY_ID, CLASS_NOT_FOUND)

#############################################################################################
# Private

proc processPacket(client : ClientData, packet : LimitedStream) {.async.} =
    # Process packet from client
    let packetId = packet.readUint8()
    var response : LimitedStream = newLimitedStream()
    case packetId
    of ADD_NEW_CLASS:
        await processAddNewClass(packet, response)
    of GET_CLASS_BY_ID:
        await processGetClassById(packet, response)
    else: 
        raise newException(Exception, "Unknown command")
        
    await ioDevice.send(client, response)
    

#############################################################################################
# Public

proc init*() =
    # Init workspace
    echo "Init packet processor"
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)
    echo "Init packet processor complete"