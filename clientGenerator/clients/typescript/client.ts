/**
 * For communication with server
 */
export class Client {

    /**
     * Default port
     */
    static PORT = 9001;

    /**
     * Default host
     */
    static HOST = "localhost";        

    /**
     * Protocol name
     */
    static PROTOCOL = "nimesis";

    /**
     * Buffer for packet
     */
    private buffer : BinaryData;

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
        let url = `ws://${Client.HOST}:${Client.PORT}`;
        this.socket = new WebSocket(url, Client.PROTOCOL);
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
     * Get class field value
     */
    getClassFieldValue(classId : number) : Value {
        return null;
    }

    /**
     * Get instance field value
     */
    getInstanceFieldValue(instanceId : number) : Value {            
        return null;
    }
}