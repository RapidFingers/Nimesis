import    
    asyncdispatch,
    asyncfile,
    streams

type
    # Stream with length
    LimitedStream* = ref object of RootObj
        data        :   StringStream            # Data stream
        len         :   int             # Length from cursor position to end
    
    # Buffered file wirter
    FileWriter* = ref object of LimitedStream
        file : AsyncFile

    # File reader
    FileReader* = ref object of RootObj
        file : AsyncFile

#############################################################################################
# LimitedStream

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

proc data*(this : LimitedStream) : string = 
    return this.data.data

proc readBool*(this : LimitedStream) : bool =
    # Read boolean
    result = bool(this.data.readInt8())
    this.len -= 1

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

proc addBool*(this : LimitedStream, value : bool) : void =
    # Write bool    
    this.data.write(value)
    this.len += 1

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
    # Add int32
    this.data.write(value)
    this.len += 4

proc addFloat64*(this : LimitedStream, value : float64) : void =
    # Add float64
    this.data.write(value)
    this.len += 8

proc addString*(this : LimitedStream, value : string) : void =
    # Write string    
    this.data.write(value)
    this.len += value.len

proc addStringWithLen*(this : LimitedStream, value : string) : void =
    # Write string with length
    this.addUint8(uint8 value.len)
    this.data.write(value)
    this.len += value.len + 1

#############################################################################################
# File writer

proc newFileWriter*(file : AsyncFile) : FileWriter =
    # Create new file writer
    result = FileWriter(
        file : file
    )
    result.init()

proc flush*(this : FileWriter) : Future[void] {.async.} =
    # Write all data to file
    await this.file.write(this.data.data)    

#############################################################################################
# Reader

proc newFileReader*(file : AsyncFile) : FileReader =
    # Create new reader
    result = FileReader()
    result.file = file

proc readBool*(this : FileReader) : Future[bool] {.async.} =
    # Read bool
    let str = await this.file.read(1)
    result = bool str[0]

proc readString*(this : FileReader, len : uint32) : Future[string] {.async.} =
    # Read string
    result = await this.file.read(int len)

proc readStringWithLen*(this : FileReader) : Future[string] {.async.} =
    # Read string
    let str = await this.file.read(1)
    let len = uint32(str[0])
    result = await this.readString(len)

proc readUint8*(this : FileReader) : Future[uint8] {.async.} = 
    let str = await this.file.read(1)
    result = uint8 str[0]

proc readUint32*(this : FileReader) : Future[uint32] {.async.} = 
    # Read string
    let str = await this.file.read(4)
    result = ((uint8 str[0]) shl 24) + ((uint8 str[1]) shl 16) + ((uint8 str[2]) shl 8) + (uint8 str[0])

proc readInt32*(this : FileReader) : Future[int32] {.async.} = 
    # Read int32
    result = int32(await this.readUint32())

proc readUint64*(this : FileReader) : Future[uint64] {.async.} = 
    # Read uint64
    let str = await this.file.read(8)
    result = (uint64(uint8 str[7]) shl 56) + 
             (uint64(uint8 str[6]) shl 48) + 
             (uint64(uint8 str[5]) shl 40) + 
             (uint64(uint8 str[4]) shl 32) + 
             (uint64(uint8 str[3]) shl 24) + 
             (uint64(uint8 str[2]) shl 16) + 
             (uint64(uint8 str[1]) shl 8) + 
             uint64(uint8 str[0])

proc readFloat64*(this : FileReader) : Future[float64] {.async.} =
    # Read float64
    let str = await this.file.read(8)
    result = cast[float64](str)