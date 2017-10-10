namespace Utils {
    /**
     * For working with binary data
     */
    export class BinaryData {

        /**
         * Part size for buffer increment
         */
        private static PART_SIZE : number = 1024;

        /**
         * Buffer for binary data
         */
        private buffer : Uint8Array;

        /**
         * Allocated buffer size
         */
        private len : number;

        /**
         * Current read position
         */
        private pos : number;

        /**
         * Reallocate buffer
         */
        private realloc(size : number) {
            if (this.buffer != null) {
                let nbuff = new Uint8Array(size);
                nbuff.set(this.buffer);
                this.buffer = nbuff;
            } else {
                this.buffer = new Uint8Array(size);
            }
        }

        /**
         * Check is it enough size of buffer
         * @param v 
         */
        private checkSize(v : number) {
            if (this.buffer.length - this.len <= 0) this.addPart();
        }

        /**
         * Add new part
         */
        private addPart() {
            this.realloc(this.buffer.length + BinaryData.PART_SIZE);
        }

        /**
         * 
         * @param data 
         */
        constructor(data? : Uint8Array) {
            if (data != null) {
                console.log(data);
                this.buffer = data;
                this.len = data.length;
                this.pos = 0;
            } else {
                this.len = 0;
                this.realloc(BinaryData.PART_SIZE);
            }
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
        addId(v : string) {
            this.checkSize(8);                        
            let d = 16 - v.length;
            let pr = "";            
            for (let i = 1; i < d+1; i++) {
                pr += "0";
            }            
            v = pr + v;
            for (let i = v.length-2; i > -2; i-=2) {
                let c = parseInt( "0x" + (s.charAt(i) + s.charAt(i+1)));
                this.addUint8(c);
            }
        }

        /**
         * Add byte to buffer
         * @param v 
         */
        addUint8(v : number) {
            this.checkSize(1);
            this.buffer[this.len++] = v & 0xFF;            
        }

        /**
         * Add uint16
         * @param v 
         */
        addUint16(v : number) {
            this.checkSize(2);
            this.buffer[this.len++] = (v & 0xFF);
            this.buffer[this.len++] = (v & 0xFF00) >> 8;            
        }

        /**
         * Add uint32
         * @param v 
         */
        addUint32(v : number) : void {
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
       /* addUint64(v : number) : void {
            this.checkSize(8);            
            let s = v.toString(16);
            let d = 16 - s.length;
            let pr = "";            
            for (let i = 1; i < d+1; i++) {
                pr += "0";
            }            
            s = pr + s;            
            for (let i = s.length-2; i > -2; i-=2) {
                let c = parseInt( "0x" + (s.charAt(i) + s.charAt(i+1)));
                this.addUint8(c);
            }
        }*/

        /**
         * Add string with len
         * @param v 
         */
        addStringWithLen(v : string) : void {
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
        setPos(pos : number) {
            this.pos = pos;
        }

        /**
         * Set data array
         * @param v 
         */
        setData(v : Uint8Array) : void {
            this.buffer = v;
            this.len = this.buffer.length;
        }

        /**
         * Read uint8
         */
        readUint8() : number {
            return this.buffer[this.pos++] & 0xFF;
        }

        /**
         * Read uint16
         */
        readUint16() : number {
            return (this.readUint8() << 8) + this.readUint8();
        }

        /**
         * Read uint32
         */
        readUint32() : number {
            return (this.readUint8() << 24) + (this.readUint8() << 16) + (this.readUint8() << 8) + this.readUint8();
        }

        /**
         * Read 8 byte identifier
         */
        readId() : string {
            return "";
        }

        /**
         * Return 
         */
        toData() : Uint8Array {
            return this.buffer.slice(0, this.len);
        }

        /**
         * Convert buffer to hex string
         */
        toHex() : string {
            let sb = new Array<string>();
            for(var i = 0; i < this.len; i++) {
                let l = this.buffer[i].toString(16).toUpperCase();
                if (l.length < 2) l = "0" + l;
                sb.push(l)
            }
            return sb.join("_");
        }
    }
}