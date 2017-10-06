import
    strutils,
    asyncdispatch,
    ioProducer,
    ../../shared/coreTypes,
    ../../shared/streamProducer,
    ../../shared/packetPacker

let io = newIoDevice()
waitFor io.connect()

proc addClass() {.async.} =    
    for i in 0..100:        
        discard await io.addClass(
            newAddClass(
                name = "Weapon_$1" % ($i),
                parentId = 0
            )
        )

    # for c in io.allClasses():
    #     echo c.name

proc addInstance() : Future[uint64] {.async.} =    
    let resp = await io.addInstance(
        newAddInstance(
            name = "User",
            classId = 1507226558501763'u64
        )
    )
    result = resp.instanceId

proc allClasses() {.async.} =
    for c in io.allClasses():
        echo c.name

waitFor addClass()
#echo waitFor addInstance()
#waitFor allClasses()
