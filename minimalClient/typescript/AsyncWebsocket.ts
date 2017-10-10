namespace Utils {
    export class AsyncWebsocket {
        /**
         * Websocket
         */
        private socket : WebSocket;

        /**
         * Is service open
         */
        private isOpen : boolean;
        
        /**
         * Server host
         */
        private host : string;

        /**
         * Server port
         */
        private port : number;

        /**
         * Protocol name
         */
        private protocol : string;

        /**
         * Constructor
         * @param host 
         * @param port 
         */
        constructor(host : string, port : number, protocol : string) {
            this.host = host;
            this.port = port;
            this.protocol = protocol;
        }

        /**
         * Open websocket
         */
        async open() : Promise<void> {
            return new Promise<void>((resolve, reject) => {
                if (this.isOpen) {
                    resolve();
                    return;
                }
                
                this.isOpen = false;
                if (this.socket != null) this.socket.close();
                let url = `ws://${this.host}:${this.port}`;
                this.socket = new WebSocket(url, this.protocol);
                this.socket.binaryType = "arraybuffer";
                this.socket.onopen = () => {
                    this.isOpen = true;
                    resolve();
                };
            });
        }

        /**
         * Send data
         * @param data 
         */
        send(data : BinaryData) : void {
            console.log(data.toHex());
            this.socket.send(data.toData());
        }

        /**
         * Read data
         */
        async read() : Promise<BinaryData> {
            return new Promise<BinaryData>((resolve, reject) => {
                this.socket.onmessage = function(e) {
                    let d = new Uint8Array(e.data);
                    let bd = new BinaryData(d);
                    console.log(bd.toHex());
                    resolve(bd);
                    this.onmessage = null;
                }
            });
        }
    }
}