import
    asyncdispatch,
    tables,
    times,    
    variant,
    ioDevice,    
    producer,
    storage

# Get class command
const GET_CLASS_BY_ID = 1

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    result = Workspace()

proc processGetClass(packet : LimitedStream) : Future[void] {.async.} = 
    # Process get class packet
    let classId = packet.readUint64()
    let len = int packet.readUint8()
    let name = packet.readString(len)
    let parentId = packet.readUint64()
    let parent = storage.getClassById(parentId)
    let nclass = producer.newClass(classId, name, parent)
    await storage.storeNewClass(nclass)

#############################################################################################
# Private
proc processPacket(client : ClientData, packet : LimitedStream) {.async.} =
    # Process packet from client
    let packetId = packet.readUint8()
    case packetId
    of GET_CLASS_BY_ID: await processGetClass(packet)
    else: raise newException(Exception, "Unknown command")

#############################################################################################
# Public

proc init*() =
    # Init workspace
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)