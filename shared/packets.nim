#############################################################################################
# Return codes

# Ok code
const OK_RESPONSE* = 1
# Error code
const ERROR_RESPONSE* = 2

#############################################################################################
# Packet codes

# Add new class
const ADD_NEW_CLASS* = 1
# Add new class field
const ADD_NEW_FIELD* = 2
# Add new class
const ADD_NEW_INSTANCE* = 3
# Get field value
const GET_FIELD_VALUE* = 4
# Set field value
const SET_FIELD_VALUE* = 5
# Get class by id
const GET_CLASS_BY_ID* = 6
# Get instance by id
const GET_INSTANCE_BY_ID* = 7
# Invoke method
const INVOKE_METHOD_BY_ID* = 8

#############################################################################################
# Process errors

# Class not found in storage
const CLASS_NOT_FOUND* = 1
# Instance not found in storage
const INSTANCE_NOT_FOUND* = 2
# Field not found in storage
const FIELD_NOT_FOUND* = 3
# Value not found in storage
const VALUE_NOT_FOUND* = 4