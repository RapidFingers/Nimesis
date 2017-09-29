import streams

type
    # Stream with length
    LimitedStream* = ref object of RootObj
        data        :   StringStream            # Data stream
        len         :   int             # Length from cursor position to end

proc init*(this : LimitedStream) =
    # Init limited string
    this.data = newStringStream()
    this.len = 0

proc newLimitedStream*() : LimitedStream =
    result = new LimitedStream
    result.init()
    
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

proc toStart*(this : LimitedStream) : void =
    # Go to start of stream
    this.setDataPos(0)

proc len*(this : LimitedStream) : int = 
    return this.len

proc readBool*(this : LimitedStream) : bool =
    # Read boolean
    result = bool(this.data.readInt8())

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

proc readInt32*(this : LimitedStream) : int32 =
    # Read int32
    result = this.data.readInt32()
    this.len -= 4

proc readString*(this : LimitedStream, len : int) : string =
    # Read string
    result = this.data.readStr(int len)
    this.len -= len

proc readStringWithLen*(this : LimitedStream) : string =
    # Read string with length
    let len = int this.readUint8()
    result = this.data.readStr(len)
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

proc addUint64*(this : LimitedStream, value : uint64) : void =
    # Write uint64
    this.data.write(value)
    this.len += 8

proc addInt32*(this : LimitedStream, value : int32) : void =
    # Read int32
    this.data.write(value)
    this.len += 4

proc addString*(this : LimitedStream, value : string) : void =
    # Write string    
    this.data.write(value)
    this.len += value.len

proc addStringWithLen*(this : LimitedStream, value : string) : void =
    # Write string with length
    this.addUint8(uint8 value.len)
    this.data.write(value)
    this.len += value.len + 1