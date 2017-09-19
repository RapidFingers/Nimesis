import 
    asyncdispatch,
    variant,
    ioDevice,
    packetProcessor,
    producer,
    storage

# Init director work
#io.init()
#packetProcessor.init()

producer.init()
storage.init()

let cls = storage.getClassById(1505844713748267'u64)
echo cls.name

#var cls = producer.newClass("BaseClass")
#waitFor storage.storeNewClass(cls)

# let cls = logic.getClassById(9787345)
# if cls.isNil:
#     echo "FUCK"
# else:
#     echo cls.parent.name

# var ent = AddClass()
# ent.id = 1242345346
# ent.name = "Batman"
# waitFor storage.logAddClass(ent)

# var ent2 = AddClass()
# ent2.id = 9787345
# ent2.name = "Superman"
# ent2.parent = ent.id
# waitFor storage.logAddClass(ent2)

# var fld = AddField()
# fld.id = 32423
# fld.parent = ent2.id
# fld.name = "Name"
# waitFor storage.logAddField(fld)

# var vl = FieldValue()
# vl.id = fld.id
# vl.valueType = STRING
# vl.value = newVariant("FUCKING Shit")
# waitFor storage.logSetValue(vl)