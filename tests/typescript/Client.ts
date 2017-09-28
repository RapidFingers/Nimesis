namespace Service {

    /**
     * For communication with server
     */
    export class Client {

        /**
         * Url for server
         */
        static URL = "ws://localhost:9001";

        /**
         * Protocol name
         */
        static PROTOCOL = "nimesis";

        /**
         * Buffer for packet
         */
        private buffer : Utils.BinaryData;

        /**
         * Websocket
         */
        private socket : WebSocket;

        /**
         * Is service open
         */
        private isOpen : boolean;

        /**
         * On open
         */
        onOpen : () => void;        

        constructor() {
            this.buffer = new Utils.BinaryData();
        }

        /**
         * Open channel
         */
        open() {
            this.isOpen = false;
            if (this.socket != null) this.socket.close();
            this.socket = new WebSocket(Client.URL, Client.PROTOCOL);
            this.socket.binaryType = "arraybuffer";            
            this.socket.onopen = () => {
                this.isOpen = true;
                this.onOpen();
            };
            this.socket.onmessage = (e) => {
                let data = new Uint8Array(e.data)
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
        getClassById(classId : number) {
            this.buffer.clear();            
            this.buffer.addUint8(2); // Packet id getClassById
            this.buffer.addUint64(classId);
            let data = this.buffer.toData();
            console.log(this.buffer.toHex());
            this.socket.send(data);
        }
    }
}