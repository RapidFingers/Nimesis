import
    times,
    strutils,
    asyncdispatch,
    ../common/ioProducer
    # ../../../shared/coreTypes,
    # ../../../shared/streamProducer,
    # ../../../shared/packetPacker,
    # ../../../shared/valuePacker

const fl : string = readFile("./clients/typescript/tsconfig.json")

type Workspace = ref object
    io : IODevice

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    workspace = Workspace(
        io : newIoDevice()
    )

proc produceClient*() {.async.} =
    # Produce client for typescript
    echo fl

    # workspace = newWorkspace()
    # await workspace.io.connect()

    # for c in workspace.io.allClasses():
    #     discard
