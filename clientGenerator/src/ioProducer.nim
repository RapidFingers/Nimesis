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

proc sendRequest(this : IODevice, req : RequestPacket) : Future[ResponsePacket] {.async.} =
    # Send request
    let stream = packetPacker.packRequest(req)
    await this.sock.sendBinary(stream.data, false)
    let f = await this.sock.readData(true)
    if f.opcode != Opcode.Binary:
        raise newException(Exception, "Only binary frame allowed")
    result = packetPacker.unpackResponse(f.data)

proc addNewClass*(this : IODevice, req : AddClassRequest) : Future[ResponsePacket] {.async.} =
    # Add new class
    result = await this.sendRequest(req)

proc addNewInstance*(this : IODevice, req : AddInstanceRequest) : Future[ResponsePacket] {.async.} =
    # Add new instance
    result = await this.sendRequest(req)

proc addNewField*(this : IODevice, req : AddFieldRequest) : Future[ResponsePacket] {.async.} =
    # Add new field
    result = await this.sendRequest(req)