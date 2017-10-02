import 
    asyncdispatch,
    ioDevice,
    packetProcessor,
    entityProducer,
    storage

storage.init()
entityProducer.init()
ioDevice.init()
packetProcessor.init()

ioDevice.listen()