import 
    asyncdispatch,
    ioDevice,
    packetProcessor,
    entityProducer,
    storage

proc initAll() {.async.} =
    # Init all modules
    await storage.init()
    entityProducer.init()
    ioDevice.init()
    packetProcessor.init()
    await ioDevice.listen()

waitFor initAll()