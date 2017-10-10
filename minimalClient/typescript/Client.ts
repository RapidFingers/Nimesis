namespace Utils {
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
         * Async web socket client
         */
        private aws : AsyncWebsocket;

        /**
         * Send data
         */
        private send(request : RequestPacket) : void {
            this.aws.send(request.pack());
        }

        /**
         * Check response for error
         * @param response 
         */
        private checkResponseError(response : ResponsePacket) {
            if (response.code == ResponseCode.ERROR_CODE) throw new Error(`Error ${response.id} - ${response.code}`);
        }

        /**
         * Constructor
         */
        constructor() {
            this.aws = new AsyncWebsocket(Client.HOST, Client.PORT, Client.PROTOCOL);
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
        async addClass(name : string, parent : RClass) : Promise<number> {
            await this.aws.open();
            var parentId = 0;
            if (parent != null) parentId = parent.id;
            this.send(new AddClassRequest(name, parentId));
            let data = await this.aws.read();
            let resp = ResponsePacket.unpack(data);
            this.checkResponseError(resp);
            let rs = resp as AddClassResponse;
            return rs.classId;
        }

        /**
         * Add new instance of class
         * @param name 
         * @param clazz 
         */
        addInstance(name : string, clazz : RClass) {
            
        }

        /**
         * Add new field of class
         * @param name 
         * @param clazz 
         * @param valueType 
         */
        addClassField(name : string, clazz : RClass, valueType : ValueType) {

        }

        /**
         * Add new field of class
         * @param name 
         * @param clazz 
         * @param valueType
         */
        addInstanceField(name : string, clazz : RClass, valueType : ValueType) {
            
        }

        /**
         * Get class field value
         */
        getClassFieldValue(classId : RClass) : Value {
            return null;
        }

        /**
         * Get instance field value
         */
        getInstanceFieldValue(instanceId : RInstance) : Value {
            return null;
        }
    }
}