import
    asyncdispatch,
    asyncfile,
    binaryPacker

type
    # Write to file
    FileWriter = ref object of LimitedStream
        file : AsyncFile

proc flush(this : FileWriter) : Future[void] {.async.} =
    # Write all data to file
    await this.file.write(this.data)