import
    asyncdispatch,
    asyncnet,
    websocket,
    ../../shared/streamProducer,
    ../../shared/coreTypes,
    ../../shared/packetPacker

# Device for contacting with server
type IODevice* = ref object of RootObj
    ws : AsyncWebSocket
    sock : AsyncSocket

proc newIoDevice*() : IODevice =
    # Create new io device
    result = IODevice()

proc readData(this : IODevice) : Future[string] {.async.} =
    # Read data from socket
    let f = await this.sock.readData(true)
    if f.opcode != Opcode.Binary:
        raise newException(Exception, "Only binary frame allowed")
    result = f.data

proc checkError(response : ResponsePacket) : void =
    # Check response on error
    if (response.code == ERROR_CODE) and (response of ErrorResponse): 
        let error = ErrorResponse(response)
        raise newException(Exception, $(error.errorCode))

proc connect*(this : IODevice) : Future[void] {.async.} =
    # Connect to server
    this.ws = await newAsyncWebsocket(
        "localhost",
        Port DEFAULT_SERVER_PORT,
        "",
        ssl = false,
        protocols = @[NIMESIS_PROTOCOL]
    )
    this.sock = this.ws.sock

proc sendRequest(this : IODevice, stream : LimitedStream) : Future[ResponsePacket] {.async.} =
    # Send request
    await this.sock.sendBinary(stream.data, false)
    let data = await this.readData()
    result = packetPacker.unpackResponse(data)
    checkError(result)

proc addClass*(this : IODevice, req : AddClassRequest) : Future[ResponsePacket] {.async.} =
    # Add new class    
    let stream = newLimitedStream()
    packetPacker.packRequest(stream, req)
    result = await this.sendRequest(stream)

proc addInstance*(this : IODevice, req : AddInstanceRequest) : Future[ResponsePacket] {.async.} =
    # Add new instance
    let stream = newLimitedStream()
    packetPacker.packRequest(stream, req)
    result = await this.sendRequest(stream)

proc addField*(this : IODevice, req : AddFieldRequest) : Future[ResponsePacket] {.async.} =
    # Add new field
    let stream = newLimitedStream()
    packetPacker.packRequest(stream, req)
    result = await this.sendRequest(stream)

iterator allClasses*(this : IODevice) : GetAllClassResponse =
    # Iterate all classes
    let stream = newLimitedStream()
    packetPacker.packRequest(stream, newGetAllClass())    
    waitFor this.sock.sendBinary(stream.data, false)        
    let data = waitFor this.readData()
    var rsp = packetPacker.unpackResponse(data)
    checkError(rsp)    
    var resp = GetAllClassResponse(rsp)
    yield resp
    while not resp.isEnd:
        let data = waitFor this.readData()
        rsp = packetPacker.unpackResponse(data)
        checkError(rsp)
        resp = GetAllClassResponse(rsp)
        yield resp