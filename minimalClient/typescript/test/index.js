var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var Utils;
(function (Utils) {
    class AsyncWebsocket {
        /**
         * Constructor
         * @param host
         * @param port
         */
        constructor(host, port, protocol) {
            this.host = host;
            this.port = port;
            this.protocol = protocol;
        }
        /**
         * Open websocket
         */
        open() {
            return __awaiter(this, void 0, void 0, function* () {
                return new Promise((resolve, reject) => {
                    if (this.isOpen) {
                        resolve();
                        return;
                    }
                    this.isOpen = false;
                    if (this.socket != null)
                        this.socket.close();
                    let url = `ws://${this.host}:${this.port}`;
                    this.socket = new WebSocket(url, this.protocol);
                    this.socket.binaryType = "arraybuffer";
                    this.socket.onopen = () => {
                        this.isOpen = true;
                        resolve();
                    };
                });
            });
        }
        /**
         * Send data
         * @param data
         */
        send(data) {
            console.log(data.toHex());
            this.socket.send(data.toData());
        }
        /**
         * Read data
         */
        read() {
            return __awaiter(this, void 0, void 0, function* () {
                return new Promise((resolve, reject) => {
                    this.socket.onmessage = function (e) {
                        let d = new Uint8Array(e.data);
                        let bd = new Utils.BinaryData(d);
                        console.log(bd.toHex());
                        resolve(bd);
                        this.onmessage = null;
                    };
                });
            });
        }
    }
    Utils.AsyncWebsocket = AsyncWebsocket;
})(Utils || (Utils = {}));
var Utils;
(function (Utils) {
    /**
     * For working with binary data
     */
    class BinaryData {
        /**
         *
         * @param data
         */
        constructor(data) {
            if (data != null) {
                console.log(data);
                this.buffer = data;
                this.len = data.length;
                this.pos = 0;
            }
            else {
                this.len = 0;
                this.realloc(BinaryData.PART_SIZE);
            }
        }
        /**
         * Reallocate buffer
         */
        realloc(size) {
            if (this.buffer != null) {
                let nbuff = new Uint8Array(size);
                nbuff.set(this.buffer);
                this.buffer = nbuff;
            }
            else {
                this.buffer = new Uint8Array(size);
            }
        }
        /**
         * Check is it enough size of buffer
         * @param v
         */
        checkSize(v) {
            if (this.buffer.length - this.len <= 0)
                this.addPart();
        }
        /**
         * Add new part
         */
        addPart() {
            this.realloc(this.buffer.length + BinaryData.PART_SIZE);
        }
        /**
         * "Clear" data
         */
        clear() {
            this.len = 0;
            this.pos = 0;
        }
        /**
         * Add 8 bytes identifier from hex string
         * @param v
         */
        addId(v) {
            this.checkSize(8);
            for (var i = 0; i < v.length; i += 2) {
                var c = parseInt("0x" + (v.charAt(i) + v.charAt(i + 1)));
                this.buffer[this.len++] = c;
            }
        }
        /**
         * Add byte to buffer
         * @param v
         */
        addUint8(v) {
            this.checkSize(1);
            this.buffer[this.len++] = v & 0xFF;
        }
        /**
         * Add uint16
         * @param v
         */
        addUint16(v) {
            this.checkSize(2);
            this.buffer[this.len++] = (v & 0xFF);
            this.buffer[this.len++] = (v & 0xFF00) >> 8;
        }
        /**
         * Add uint32
         * @param v
         */
        addUint32(v) {
            this.checkSize(4);
            this.buffer[this.len++] = (v & 0xFF);
            this.buffer[this.len++] = (v & 0xFF00) >> 8;
            this.buffer[this.len++] = (v & 0xFF0000) >> 16;
            this.buffer[this.len++] = (v & 0xFF000000) >> 24;
        }
        /**
         * Add string with len
         * @param v
         */
        addStringWithLen(v) {
            this.checkSize(v.length + 1);
            this.buffer[this.len++] = v.length;
            for (var i = 0; i < v.length; i++) {
                var c = v.charCodeAt(i);
                this.addUint8(c);
            }
        }
        /**
         * Set reading position
         * @param pos
         */
        setPos(pos) {
            this.pos = pos;
        }
        /**
         * Set data array
         * @param v
         */
        setData(v) {
            this.buffer = v;
            this.len = this.buffer.length;
        }
        /**
         * Read uint8
         */
        readUint8() {
            return this.buffer[this.pos++] & 0xFF;
        }
        /**
         * Read uint16
         */
        readUint16() {
            return (this.readUint8() << 8) + this.readUint8();
        }
        /**
         * Read uint32
         */
        readUint32() {
            return (this.readUint8() << 24) + (this.readUint8() << 16) + (this.readUint8() << 8) + this.readUint8();
        }
        /**
         * Read 8 byte identifier
         */
        readId() {
            let res = "";
            for (let i = 0; i < 8; i++) {
                let d = this.buffer[this.pos++].toString(16);
                if (d.length < 2)
                    d = "0" + d;
                res += d;
            }
            return res;
        }
        /**
         * Return
         */
        toData() {
            return this.buffer.slice(0, this.len);
        }
        /**
         * Convert buffer to hex string
         */
        toHex() {
            let sb = new Array();
            for (var i = 0; i < this.len; i++) {
                let l = this.buffer[i].toString(16).toUpperCase();
                if (l.length < 2)
                    l = "0" + l;
                sb.push(l);
            }
            return sb.join("_");
        }
    }
    /**
     * Part size for buffer increment
     */
    BinaryData.PART_SIZE = 1024;
    Utils.BinaryData = BinaryData;
})(Utils || (Utils = {}));
var Utils;
(function (Utils) {
    /**
     * For communication with server
     */
    class Client {
        /**
         * Constructor
         */
        constructor() {
            this.aws = new Utils.AsyncWebsocket(Client.HOST, Client.PORT, Client.PROTOCOL);
        }
        /**
         * Send data
         */
        send(request) {
            this.aws.send(request.pack());
        }
        /**
         * Check response for error
         * @param response
         */
        checkResponseError(response) {
            if (response.code == Utils.ResponseCode.ERROR_CODE)
                throw new Error(`Error ${response.id} - ${response.code}`);
        }
        /**
         * Get all classes
         */
        getClasses() {
        }
        /**
         * Iterate all instances
         */
        getInstances() {
        }
        /**
         * Add new class
         * @param name
         * @param parent
         */
        addClass(name, parentId) {
            return __awaiter(this, void 0, void 0, function* () {
                yield this.aws.open();
                var pId = Utils.BasePacket.EMPTY_ID;
                if (parentId != null)
                    pId = parentId;
                this.send(new Utils.AddClassRequest(name, parentId));
                let data = yield this.aws.read();
                let resp = Utils.ResponsePacket.unpack(data);
                this.checkResponseError(resp);
                let rs = resp;
                return rs.classId;
            });
        }
        /**
         * Add new instance of class
         * @param name
         * @param clazz
         */
        addInstance(name, clazz) {
        }
        /**
         * Add new field of class
         * @param name
         * @param clazz
         * @param valueType
         */
        addClassField(name, clazz, valueType) {
        }
        /**
         * Add new field of class
         * @param name
         * @param clazz
         * @param valueType
         */
        addInstanceField(name, clazz, valueType) {
        }
        /**
         * Get class field value
         */
        getClassFieldValue(classId) {
            return null;
        }
        /**
         * Get instance field value
         */
        getInstanceFieldValue(instanceId) {
            return null;
        }
    }
    /**
     * Default port
     */
    Client.PORT = 9001;
    /**
     * Default host
     */
    Client.HOST = "localhost";
    /**
     * Protocol name
     */
    Client.PROTOCOL = "nimesis";
    Utils.Client = Client;
})(Utils || (Utils = {}));
var Utils;
(function (Utils) {
    /**
     * Request types
     */
    let RequestType;
    (function (RequestType) {
        RequestType[RequestType["ADD_CLASS_REQUEST"] = 0] = "ADD_CLASS_REQUEST";
    })(RequestType = Utils.RequestType || (Utils.RequestType = {}));
    /**
     * Response types
     */
    let ResponseType;
    (function (ResponseType) {
        ResponseType[ResponseType["INTERNAL_ERROR"] = 0] = "INTERNAL_ERROR";
        ResponseType[ResponseType["ADD_CLASS_RESPONSE"] = 1] = "ADD_CLASS_RESPONSE";
    })(ResponseType = Utils.ResponseType || (Utils.ResponseType = {}));
    /**
     * Response codes
     */
    let ResponseCode;
    (function (ResponseCode) {
        ResponseCode[ResponseCode["OK_CODE"] = 0] = "OK_CODE";
        ResponseCode[ResponseCode["ERROR_CODE"] = 1] = "ERROR_CODE";
    })(ResponseCode = Utils.ResponseCode || (Utils.ResponseCode = {}));
    /**
     * Base packet
     */
    class BasePacket {
    }
    /**
     * Empty entity Id
     */
    BasePacket.EMPTY_ID = "0000000000000000";
    Utils.BasePacket = BasePacket;
    /**
     * Packet of request
     */
    class RequestPacket {
    }
    Utils.RequestPacket = RequestPacket;
    /**
     * Response packet
     */
    class ResponsePacket {
        /**
         * Unpack binary data to packet
         */
        static unpack(data) {
            let id = data.readUint8();
            let code = data.readUint8();
            if (code == ResponseCode.ERROR_CODE) {
                let errorCode = data.readUint8();
                return new ErrorResponse(id, errorCode);
            }
            let resp;
            switch (id) {
                case ResponseType.ADD_CLASS_RESPONSE:
                    resp = AddClassResponse.unpack(data);
                    break;
            }
            if (resp == null)
                throw new Error("Unknown response");
            resp.id = id;
            resp.code = code;
            return resp;
        }
    }
    Utils.ResponsePacket = ResponsePacket;
    /**
     * Error response
     */
    class ErrorResponse extends ResponsePacket {
        /**
         * Constructor
         * @param id
         * @param errorCode
         */
        constructor(id, errorCode) {
            super();
            this.id = id;
            this.code = ResponseCode.ERROR_CODE;
            this.errorCode = errorCode;
        }
    }
    Utils.ErrorResponse = ErrorResponse;
    /**
     * Add class request
     */
    class AddClassRequest extends RequestPacket {
        /**
         * Constructor
         * @param name
         * @param parentId
         */
        constructor(name, parentId) {
            super();
            this.name = name;
            this.parentId = parentId;
        }
        /**
         * Convert packet to binary data
         */
        pack() {
            let bd = new Utils.BinaryData();
            bd.addUint8(RequestType.ADD_CLASS_REQUEST);
            bd.addStringWithLen(this.name);
            if (this.parentId != null) {
                bd.addId(this.parentId);
            }
            else {
                bd.addId(BasePacket.EMPTY_ID);
            }
            return bd;
        }
    }
    Utils.AddClassRequest = AddClassRequest;
    /**
     * Response for add class request
     */
    class AddClassResponse extends ResponsePacket {
        /**
         * Unpack
         * @param data
         */
        static unpack(data) {
            let res = new AddClassResponse();
            res.classId = data.readId();
            return res;
        }
    }
    Utils.AddClassResponse = AddClassResponse;
})(Utils || (Utils = {}));
var Utils;
(function (Utils) {
    /**
     * Referrence class entity
     */
    class REntity {
        /**
         * Constructor
         */
        constructor() {
        }
    }
    Utils.REntity = REntity;
    /**
     * Referrence class entity
     */
    class RClass extends REntity {
        /**
         * Constructor
         */
        constructor() {
            super();
        }
    }
    Utils.RClass = RClass;
    /**
     * Referrence instance entity
     */
    class RInstance extends REntity {
    }
    Utils.RInstance = RInstance;
})(Utils || (Utils = {}));
var Utils;
(function (Utils) {
    /**
     * Possible value types
     */
    let ValueType;
    (function (ValueType) {
        ValueType[ValueType["INT"] = 0] = "INT";
        ValueType[ValueType["FLOAT"] = 1] = "FLOAT";
        ValueType[ValueType["STRING"] = 2] = "STRING";
    })(ValueType = Utils.ValueType || (Utils.ValueType = {}));
    /**
     * Base class for value
     */
    class Value {
    }
    Utils.Value = Value;
    /**
     * Int value
     */
    class ValueInt extends Value {
    }
    Utils.ValueInt = ValueInt;
})(Utils || (Utils = {}));
/**
 * Start game when all dom loaded
 */
window.addEventListener('DOMContentLoaded', () => __awaiter(this, void 0, void 0, function* () {
    let client = new Utils.Client();
    let id = yield client.addClass("BaseClass", null);
    console.log(id);
    let id2 = yield client.addClass("Weapon", id);
    console.log(id2);
}));
//# sourceMappingURL=index.js.map