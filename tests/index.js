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
         * Add uint64
         * @param v
         */
        addUint64(v) {
            let s = v.toString(16);
            console.log(s);
            for (let i = 0; i < s.length; i += 2) {
                let c = parseInt("0x" + (s.charAt(i) + s.charAt(i + 1)));
                console.log(c);
                this.addUint8(c);
            }
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
var Service;
(function (Service) {
    /**
     * For communication with server
     */
    class Client {
        constructor() {
            this.buffer = new Utils.BinaryData();
        }
        /**
         * Open channel
         */
        open() {
            this.isOpen = false;
            if (this.socket != null)
                this.socket.close();
            this.socket = new WebSocket(Client.URL, Client.PROTOCOL);
            this.socket.binaryType = "arraybuffer";
            this.socket.onopen = () => {
                this.isOpen = true;
                this.onOpen();
            };
            this.socket.onmessage = (e) => {
                let data = new Uint8Array(e.data);
                console.log(data);
            };
            this.socket.onclose = (e) => {
                console.log(e);
            };
            this.socket.onerror = (e) => {
                console.log(e);
            };
        }
        /**
         * Get class by id
         */
        getClassById(classId) {
            this.buffer.clear();
            this.buffer.addUint8(2); // Packet id getClassById
            this.buffer.addUint64(classId);
            let data = this.buffer.toData();
            console.log(this.buffer.toHex());
            this.socket.send(data);
        }
    }
    /**
     * Url for server
     */
    Client.URL = "ws://localhost:9001";
    /**
     * Protocol name
     */
    Client.PROTOCOL = "nimesis";
    Service.Client = Client;
})(Service || (Service = {}));
/**
 * Start game when all dom loaded
 */
window.addEventListener('DOMContentLoaded', () => __awaiter(this, void 0, void 0, function* () {
    let gs = new Service.Client();
    gs.onOpen = () => {
        console.log("OPENED");
        gs.getClassById(1505844713748267);
    };
    // gs.onPacket = (packet) => {
    //     console.log(packet);
    // }
    gs.open();
}));
//# sourceMappingURL=index.js.map