import
    times,
    strutils,
    asyncdispatch,
    ../common/ioProducer
    # ../../../shared/coreTypes,
    # ../../../shared/streamProducer,
    # ../../../shared/packetPacker,
    # ../../../shared/valuePacker

type Workspace = ref object
    io : IODevice

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace(
        io : newIoDevice()
    )

proc produceClient*() {.async.} =
    # Produce client for typescript

    workspace = newWorkspace()
    await workspace.io.connect()

    for c in workspace.io.allClasses():
        echo c.name