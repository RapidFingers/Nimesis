import 
    websocket, 
    asyncnet, 
    asyncdispatch,
    ../../shared/limitedStream


let ws = waitFor newAsyncWebsocket("localhost", Port 9001, "", ssl = false, protocols = @["nimesis"])
let ds = newLimitedStream()
ds.addUint8(1)
ds.setDataPos(0)
waitFor ws.sock.sendBinary(ds.readString(ds.len), true)