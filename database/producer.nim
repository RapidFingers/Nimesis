import
    times,
    tables,
    variant

#############################################################################################
# Products
type
    # Possible value types to store
    ValueType* = enum
        INT = 0, 
        STRING = 1, 
        FLOAT = 2

    # Unique id
    UniqueId* = BiggestUInt

    # Base entity
    Entity* = ref object of RootObj
        id* : UniqueId                      # Id of entity
        name* : string                       # Name of entity
        caption* : UniqueId                  # Reference to caption

    # Field of class or instance
    Field* = ref object of Entity        
        parent : EntityWithValues           # Parent entity
        valueType : ValueType               # Value type

    # Argument of method
    Argument = ref object of RootObj
        name : string                       # Name of argument
        valueType : ValueType               # Value type
        value : Variant                     # Value of argument

    # Method
    Method* = ref object of Entity
        parent : Entity                     # Parent entity
        arguments : seq[Argument]
        returnArg : Argument

    Interface* = ref object of Entity
        parent* : Interface                  # Parent interface
        fields* : seq[Field]                 # Interface fields  
        methods* : seq[Method]               # Interface methods

    EntityWithValues = ref object of Entity
        values* : TableRef[UniqueId, Variant]      # Values for class fields

    # Class entity
    Class* = ref object of EntityWithValues        
        parent* : Class                      # Parent class
        interfaces* : seq[Interface]         # Class interfaces
        classFields* : seq[Field]            # Class static fields
        instanceFields* : seq[Field]         # Instance fields        
        classMethods* : seq[Method]          # Class methods
        instanceMethods* : seq[Method]       # Instance methods
        instances* : seq[Instance]           # Instances of class
        childClasses* : seq[Class]           # Child classes


    # Instance entity
    Instance* = ref object of EntityWithValues
        classId : UniqueId                  # For lazy loading
        class : Class                       # Class of instance 

#############################################################################################
# Workspace of producer
type Workspace = ref object
var workspace {.threadvar.} : Workspace

proc newWorkspace() : Workspace =
    # Create new workspace
    result = Workspace()

#############################################################################################
# Utility

# Create new id
template newId() : UniqueId = UniqueId(epochTime() * 1000000)

#############################################################################################
# Entity

proc initEntity(this : Entity, name : string) {.inline.} =
    # Init entity    
    this.name = name

#############################################################################################
# EntityWithValues

proc initEntityWithValues(this : EntityWithValues, name : string) {.inline.} =
    # Init entity with values
    this.initEntity(name)
    this.values = newTable[UniqueId, Variant](1)

#############################################################################################
# Class

proc initClass(this : Class, name : string, parent : Class) {.inline.} = 
    # Init class
    this.initEntityWithValues(name)    
    this.parent = parent
    this.interfaces = @[]
    this.classFields = @[]
    this.instanceFields = @[]
    this.classMethods = @[]
    this.instanceMethods = @[]    
    this.instances = @[]
    this.childClasses = @[]

#############################################################################################
# Instance

proc initInstance(this : Instance, name : string, class : Class) {.inline.} =
    # Init instance
    this.initEntityWithValues(name)
    this.class = class

#############################################################################################
# Public interface

proc newClass*(name : string) : Class =
    # Create new class
    result = Class()
    result.initClass(name, nil)
    result.id = newId()

proc newClass*(name : string, parent : Class) : Class =
    # Create new class
    result = Class()
    result.initClass(name, parent)
    result.id = newId()
    result.parent = parent
    parent.childClasses.add(result)

proc newClass*(id : UniqueId, name : string) : Class =
    # Create new class
    result = Class()
    result.initClass(name, nil)
    result.id = id

proc newClass*(id : UniqueId, name : string, parent : Class) : Class =
    # Create new class
    result = Class()
    result.initClass(name, parent)
    result.id = id
    result.parent = parent
    parent.childClasses.add(result)

proc init*() =
    # Init producer
    workspace = newWorkspace()