import    
    asyncdispatch,
    ioProducer,
    ../../shared/coreTypes,
    ../../shared/streamProducer

let io = newIoDevice()
waitFor io.connect()