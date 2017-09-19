import  
    websocket, 
    asynchttpserver,
    asyncnet,
    asyncdispatch,
    strutils,
    streams

#############################################################################################
# Limited stream
type
    # Client packet
    LimitedStream* = ref object of RootObj
        data        :   StringStream            # Data stream
        len         :   int             # Length from cursor position to end

proc init*(this : LimitedStream) =
    # Init limited string
    this.data = newStringStream()
    this.len = 0

proc newLimitedStream*() : LimitedStream =
    result = new LimitedStream
    result.init
    
proc clear*(this : LimitedStream) : void =
    # Reset stream
    this.data.setPosition(0)
    this.len = 0

proc setData*(this : LimitedStream, data : string) : void =
    # Set stream data
    this.data.data = data
    this.len = data.len
    setPosition(this.data, 0)

proc setDataPos*(this : LimitedStream, pos : int) : void = 
    # Set read position
    this.data.setPosition(pos)
    this.len = this.len - pos

proc len*(this : LimitedStream) : int = 
    return this.len

proc readUint8*(this : LimitedStream) : uint8 =
    # Read uint8
    result = uint8(this.data.readInt8())
    this.len -= 1

proc readUint16*(this : LimitedStream) : uint16 =
    # Read uint16
    result = uint16(this.data.readInt16)
    this.len -= 2

proc readUint32*(this : LimitedStream) : uint32 =
    # Read uint32
    result = uint32(this.data.readInt32)
    this.len -= 4

proc readUint64*(this : LimitedStream) : uint64 =
    # Read uint64
    result = uint64(this.data.readInt64)
    this.len -= 8

proc readString*(this : LimitedStream, len : int) : string =
    # Read string
    result = this.data.readStr(int len)
    this.len -= len
        
proc addUint8*(this : LimitedStream, value : uint8) : void =
    # Write uint8    
    this.data.write(value)
    this.len += 1

proc addUint16*(this : LimitedStream, value : uint16) : void =
    # Write uint16
    this.data.write(value)
    this.len += 2

proc addUint32*(this : LimitedStream, value : uint32) : void =
    # Write uint32
    this.data.write(value)
    this.len += 4

proc addString*(this : LimitedStream, value : string) : void =
    # Write string
    this.addUint8(uint8 value.len)
    this.data.write(value)
    this.len += value.len + 1

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
type RecievePacket* = proc(client : ClientData, packet : LimitedStream) : Future[void]
type Workspace = ref object
    onPacket : RecievePacket

proc newWorkspace() : Workspace =
    result = Workspace()

var workspace {.threadvar.} : Workspace

proc callback(request: Request) : Future[void] {.async, gcsafe.} =
    # Websocket callback
    echo "Accepted"
    let (success, error) = await(verifyWebsocketRequest(request, "bombardo"))
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
                if processFut.failed: break
            else:
                echo "Only binary protocol allowed"
                break
                
        request.client.close()
        echo "Done"

proc send*(packet : string) : void =
    # Send packet to client
    discard

proc setOnPacket*(call : RecievePacket) : void =
    # Set call on packet recieve
    workspace.onPacket = call

proc init*() =
    # Init workspace
    workspace = newWorkspace()
    var server = newAsyncHttpServer()    
    waitFor server.serve(Port(9001), callback)