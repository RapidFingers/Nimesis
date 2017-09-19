import
    strutils,
    os,
    asyncdispatch,
    asyncfile,
    tables,
    dataLogger,
    db_sqlite

const DATABASE_FILE_NAME = "database.dat"
const CREATE_DATABASE_NAME = "createDatabase.sql"

#############################################################################################
# Database sub products

#############################################################################################
# Database class

type DbClass* = ref object of RootObj
    id* : BiggestUInt
    parentId* : BiggestUInt
    name* : string

proc newDbClass(id : BiggestUInt, parentId : BiggestUInt, name : string) : DbClass =
    # Create new DbClass
    result = DbClass(id : id, parentId : parentId, name : name)

#############################################################################################
# Workspace of database
type Workspace = ref object
    db : DbConn                     # Database connection

var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

#############################################################################################
# Private

proc initDatabase() : void =
    # Init database
    if not os.fileExists(DATABASE_FILE_NAME):
        let createScript = "../assets/$1" % CREATE_DATABASE_NAME
        if not os.fileExists(createScript): 
            raise newException(Exception, "Can't find create database script")

        let file = asyncfile.openAsync(createScript, fmRead)
        let data = waitFor file.readAll()
        let db = open(DATABASE_FILE_NAME, "", "", "")
        db.exec(sql(data))
        workspace.db = db
    else:
        workspace.db = open(DATABASE_FILE_NAME, "", "", "")


#############################################################################################
# Public interface

proc writeLogRecord*(record : LogRecord) : void =
    # Write log record to database
    if record of AddClassRecord:
        let rec = AddClassRecord(record)
        workspace.db.exec(sql("INSERT INTO classes(id,parentId,name) VALUES(?,?,?)"), rec.id, rec.parentId, rec.name)

proc getAllClasses*() : TableRef[BiggestUInt, DbClass] = 
    # Iterate all classes from database
    result = newTable[BiggestUInt, DbClass]()
    for row in workspace.db.fastRows(sql("SELECT id,parentId,name FROM classes")):
        let id = parseBiggestUInt(row[0])
        result[id] = newDbClass(id, parseBiggestUInt(row[1]), row[2])

proc init*() : void =
    # Init database
    workspace = newWorkspace()
    initDatabase()
