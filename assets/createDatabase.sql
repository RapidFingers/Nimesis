CREATE TABLE IF NOT EXISTS classes (
    id INTEGER PRIMARY KEY,
    parentId INTEGER,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS instances (
    id INTEGER PRIMARY KEY,
    classId INTEGER,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS fields (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL
    isClassField INTEGER,
    classId INTEGER,
    valueType INTEGER
);

CREATE TABLE IF NOT EXISTS v_int (
    fieldId INTEGER PRIMARY KEY,
    instanceId INTEGER,
    value INTEGER
);

CREATE TABLE IF NOT EXISTS v_float (
    fieldId INTEGER PRIMARY KEY,
    instanceId INTEGER,
    value REAL
);

CREATE TABLE IF NOT EXISTS v_string (
    fieldId INTEGER PRIMARY KEY,
    instanceId INTEGER,
    value TEXT
);

CREATE TABLE IF NOT EXISTS v_entity (
    fieldId INTEGER PRIMARY KEY,
    instanceId INTEGER,
    value INTEGER
);

CREATE TABLE IF NOT EXISTS v_blob (
    fieldId INTEGER PRIMARY KEY,
    instanceId INTEGER,
    value BLOB
);