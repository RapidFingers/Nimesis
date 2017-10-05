import    
    asyncdispatch,
    ioProducer,
    ../../shared/coreTypes,
    ../../shared/streamProducer,
    ../../shared/packetPacker

proc test() {.async.} =
    let io = newIoDevice()
    await io.connect()
    # let resp = await io.addClass(
    #     newAddClass(
    #         name = "GoodClass",
    #         parentId = 0
    #     )
    # )
    # echo resp.code

    for c in io.allClasses():
        echo c.name

waitFor test()
