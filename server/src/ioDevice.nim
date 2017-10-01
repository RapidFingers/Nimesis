import  
    websocket, 
    asynchttpserver,
    asyncnet,
    asyncdispatch,
    strutils,
    streams,
    ../../shared/packetPacker,
    ../../shared/binaryPacker

# Protocol name
const PROTOCOL_NAME = "nimesis"
# Default port for recieving data
const DEFAULT_PORT = 9001
# Internal error
const INTERNAL_ERROR = 0

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
    let (success, error) = await(verifyWebsocketRequest(request, PROTOCOL_NAME))
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
                    if processFut.error of IoException:
                        let exception = IoException(processFut.error)
                        let response = newLimitedStream()
                        packetPackager.packResponse(response, exception.errorData)
                        discard send(client, response)
                        break
                    # If unknown exception
                    else:
                        let stream = newLimitedStream()
                        stream.addUint8(INTERNAL_ERROR)
                        stream.toStart()
                        discard send(client, stream)
                        echo processFut.error.msg
                        break
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
    waitFor workspace.server.serve(Port(DEFAULT_PORT), callback)

proc init*() =
    # Init workspace
    echo "Init io device"
    workspace = newWorkspace()    
    echo "Init io device complete"    