# import    
#     variant,
#     tables
 
#  #############################################################################################
# # Iterators

# iterator instanceFields*(this : Class) : Field =
#     # Get all instance fields
#     for f in this.instanceFields: yield f
#     var par = this.parent
#     while par != nil:
#         for f in par.instanceFields: yield f
#         par = par.parent

# iterator instanceFields*(this : Instance) : Field =
#     # Get all instance fields
#     for f in instanceFields(this.class): yield f

# iterator totalClassFields*(this : Class) : Field =
#     # Get all class fields
#     for f in this.classFields: yield f
#     var par = this.parent
#     while par != nil:
#         for f in par.classFields: yield f
#         par = par.parent

# proc getAllChilds(this : Class, res : var seq[seq[Class]]) : void =
#     res.add(this.childClasses)
#     for c in this.childClasses:
#         getAllChilds(c, res)

# iterator instances*(this : Class) : Instance =
#     # Iterate instances of class
#     for i in this.instances:
#         yield i

#     var res = newSeq[seq[Class]]()
#     getAllChilds(this, res)
#     for it in res:
#         for c in it:
#             for i in c.instances:
#                 yield i

# iterator childs*(this : Class) : Class =
#     # Return class childs
#     for c in this.childClasses:
#         yield c

# iterator allChilds*(this : Class) : Class =
#     # Return all class childs
#     var res = newSeq[seq[Class]]()
#     getAllChilds(this, res)
#     for it in res:
#         for c in it:            
#             yield c

# #############################################################################################
# # Field
# # proc newField(name : string, valueType : ValueType, parent : EntityWithValues) : Field =
# #     result = Field()
# #     result.id = newId()
# #     result.valueType = valueType
# #     result.name = name
# #     result.parent = parent

# proc name*(this : Field) : string {.inline.} = this.name    
#     # Get field name

# proc checkType[T](this : Field, value : T) : void {.inline.} =
#     if this.valueType == INT and not (value is int) : raise newException(Exception, "Wrong type")
#     if this.valueType == FLOAT and not (value is float) : raise newException(Exception, "Wrong type")
#     if this.valueType == STRING and not (value is string) : raise newException(Exception, "Wrong type")

# proc setValue*[T](this : Field, value : T) : void =    
#     checkType(this, value)

#     # Set value
#     let val = newVariant(value)
#     let values = this.parent.values
#     values[this.id] = val

# proc getValue*(this : Field, valueType : typedesc) : auto =
#     let values = this.parent.values
#     let val = values.getOrDefault(this.id)
#     result = val.get(valueType)

# #############################################################################################
# # Instance
# # proc newInstance(name : string, class : Class) : Instance =
# #     # Create new instance
# #     result = Instance()
# #     result.initInstance(name, class)
# #     workspace.instances[result.id] = result

# # proc getInstanceById*(id : UniqueId) : Instance =
# #     # Return instance by id
# #     result = workspace.instances.getOrDefault(id)

# proc id*(this : Instance) : UniqueId {.inline.} =
#     # Return instance class
#     result = this.id

# proc name*(this : Instance) : string {.inline.} =
#     # Return instance name
#     result = this.name

# proc class*(this : Instance) : Class {.inline.} =
#     # Return instance class
#     result = this.class

# proc getFieldById*(this : Instance, id : UniqueId) : Field = 
#     # Return field by id
#     for f in instanceFields(this.class):
#         if f.id == id: return f

# proc getFieldByName*(this : Instance, name : string) : Field = 
#     # Return field by name
#     for f in instanceFields(this.class):
#         if f.name == name: return f

# #############################################################################################
# # Class

# # proc newInstance*(this : Class, name : string) : Instance =
# #     # Create new instance
# #     result = newInstance(name, this)
# #     this.instances.add(result)
# #     #workspace.instances[result.id] = result

# # proc getClassById*(id : UniqueId) : Class =
# #     # Return class by id
# #     result = workspace.classes.getOrDefault(id)

# # proc addClassField*(this : Class, name : string, valueType : ValueType) : Field =
# #     # Add class field
# #     result = newField(name, valueType, this)
# #     this.classFields.add(result)

# # proc addInstanceField*(this : Class, name : string, valueType : ValueType) : Field =
# #     # Add instance field
# #     result = newField(name, valueType, this)
# #     this.instanceFields.add(result)
    
# # proc getFieldById*(this : Class, id : UniqueId) : Field =
# #     # Return field by id
# #     for f in totalClassFields(this):
# #         if f.id == id: return f

# # proc getFieldByName*(this : Class, name : string) : Field =
# #     # Return field by name
# #     for f in totalClassFields(this):
# #         if f.name == name: return f

# proc name*(this : Class) : string {.inline.} =
#     # Return class name
#     result = this.name

# # proc parent*(this : Class) : Class = 
# #     # Return parent
# #     if this.parent.isNil:
# #         this.parent = getClassById(this.parentId)        
    
# #     result = this.parent