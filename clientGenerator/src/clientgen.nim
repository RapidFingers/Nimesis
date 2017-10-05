import    
    asyncdispatch,
    ioProducer,
    ../../shared/coreTypes,
    ../../shared/streamProducer,
    ../../shared/packetPacker

let io = newIoDevice()
waitFor io.connect()

proc addClass() : Future[uint64] {.async.} =    
    let resp = await io.addClass(
        newAddClass(
            name = "BaseClass",
            parentId = 0
        )
    )
    result = resp.classId

    # for c in io.allClasses():
    #     echo c.name

proc addInstance() : Future[uint64] {.async.} =    
    let resp = await io.addInstance(
        newAddInstance(
            name = "User",
            #classId = 1507213082831880'u64
            classId = 1507213082831883'u64
        )
    )
    result = resp.instanceId

#echo waitFor addClass()
echo waitFor addInstance()
