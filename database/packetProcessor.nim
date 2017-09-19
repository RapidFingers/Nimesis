import
    asyncdispatch,
    tables,
    times,    
    variant,
    ioDevice,
    producer

#############################################################################################
# Workspace of packet processor
type Workspace = ref object
    classes : TableRef[UniqueId, Class]                    # All classes
    instances : TableRef[UniqueId, Instance]               # All instances    

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    result = Workspace()
    result.classes = newTable[UniqueId, Class](1)
    result.instances = newTable[UniqueId, Instance](1)

#############################################################################################

proc processPacket*(client : ClientData, packet : LimitedStream) {.async.} =
    # Process packet from client
    discard

proc init*() =
    # Init workspace
    workspace = newWorkspace()
    ioDevice.setOnPacket(processPacket)