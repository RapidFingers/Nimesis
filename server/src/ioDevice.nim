import  
    websocket, 
    asynchttpserver,
    asyncnet,
    asyncdispatch,
    strutils,
    streams,
    ../../shared/coreTypes,
    ../../shared/packetPacker,
    ../../shared/streamProducer

#############################################################################################
# Client data
type
    ClientData* = ref object
        socket* : AsyncSocket
        custom* : RootRef

proc newClientData*(socket : AsyncSocket) : ClientData =
    # Create data of client
    result = ClientData(socket : socket)

#############################################################################################
# IoException

# Send to client then something goes wrong
type IoException* = ref object of Exception
    errorData* : ErrorResponse

proc newIoException*(errorData : ErrorResponse, msg : string = "") : IoException =
    result = IoException(
        errorData : errorData,
        msg : msg
    )

#############################################################################################
type RecievePacket* = proc(client : ClientData, packet : LimitedStream) : Future[void]
type Workspace = ref object
    onPacket : RecievePacket
    server : AsyncHttpServer

proc newWorkspace() : Workspace =
    result = Workspace()
    result.server = newAsyncHttpServer()

var workspace {.threadvar.} : Workspace

proc send*(client : ClientData, packet : LimitedStream) : Future[void] {.async.}

# TODO: too complex
proc callback(request: Request) : Future[void] {.async, gcsafe.} =
    # Websocket callback
    echo "Accepted"
    let (success, error) = await(verifyWebsocketRequest(request, NIMESIS_PROTOCOL))
    if not success:
        await request.respond(Http400, "Websocket negotiation failed: " & error)
        echo error
        request.client.close()
    else:
        # New session
        var client = newClientData(request.client)
        while true:
            let readFut = request.client.readData(false)
            yield readFut
            if readFut.failed: break

            let f = readFut.read()
            if f.opcode == Opcode.Binary:
                var packet = newLimitedStream()
                packet.setData(f.data)
                let processFut = workspace.onPacket(client, packet)                
                yield processFut
                # Send internal error to client and break
                if processFut.failed:
                    # If known exception
                    var errorResponse : ErrorResponse = nil
                    if processFut.error of IoException:
                        let ioErr = IoException(processFut.error)
                        errorResponse = ioErr.errorData                        
                    # If unknown exception
                    else:
                        echo "INTERNAL ERROR"
                        errorResponse = newInternalErrorResponse()

                    let response = newLimitedStream()
                    packetPacker.packResponse(response, errorResponse)
                    discard send(client, response)
                    echo errorResponse.errorCode
                    echo processFut.error.msg
            else:
                echo "Only binary protocol allowed"
                break
                
        request.client.close()
        echo "Done"

proc send*(client : ClientData, packet : LimitedStream) : Future[void] {.async.} =
    # Send packet to client
    packet.toStart()
    await client.socket.sendBinary(packet.readString(packet.len), false)

proc setOnPacket*(call : RecievePacket) : void =
    # Set call on packet recieve
    workspace.onPacket = call

proc listen*() : void =
    # Start listen for clients
    echo "Start listening"
    waitFor workspace.server.serve(Port(DEFAULT_SERVER_PORT), callback)

proc init*() =
    # Init workspace
    echo "Init io device"
    workspace = newWorkspace()    
    echo "Init io device complete"    