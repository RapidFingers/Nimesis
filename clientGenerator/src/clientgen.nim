import
    os, 
    strutils,
    parseopt2,
    asyncdispatch,
    ./typescript/clientProducer

# let io = newIoDevice()
# waitFor io.connect()

# proc addClass() : Future[uint64] {.async.} =        
#     let resp = await io.addClass(
#         newAddClass(
#             name = "BaseClass",
#             parentId = 0
#         )
#     )
#     result = resp.classId

# proc addInstance() : Future[uint64] {.async.} =    
#     let resp = await io.addInstance(
#         newAddInstance(
#             name = "User",
#             classId = 1507280676376022'u64
#         )
#     )
#     result = resp.instanceId 

# proc addField(classId : uint64) {.async.} =    
#     let resp = await io.addField(
#         newAddField(
#             name = "email",            
#             classId = classId,
#             isClassField = true,
#             valueType = INT
#         )
#     )
#     echo resp.fieldId

# proc allClasses() {.async.} =
#     for c in io.allClasses():
#         echo c.name
#         echo c.classId

# proc allInstances() {.async.} =
#     for c in io.allInstances():
#         echo c.name
#         echo c.instanceId
#         echo c.classId

#let classId = waitFor addClass()
#echo waitFor addInstance()
#waitFor addField(classId)
#waitFor allClasses()
#waitFor allInstances()

const usageString = """
Commands:
    ts              Generate client for Typescript
    cs              Generate client for C#
    java            Generate client for Java
Example:
    clientgen -ts
    clientgen -cs
"""

when(isMainModule):
    if paramCount() < 1:
        echo ""
        echo usageString
        quit()  

    var p = initOptParser(commandLineParams())
    try:
        for kind, key, val in p.getopt():
            case kind
            of cmdLongOption, cmdShortOption:
                case key:
                of "ts": waitFor clientProducer.produceClient()
                of "cs": raise newException(Exception, "Not implemented")
                of "java": raise newException(Exception, "Not implemented")
                else:
                    raise newException(Exception, "Unknown type of target")
            else:
                raise newException(Exception, "Unknown command")
    except:
        echo getCurrentExceptionMsg()