namespace Utils {
    /**
     * Request types
     */
    export enum RequestType {
        ADD_CLASS_REQUEST
    }

    /**
     * Response types
     */
    export enum ResponseType {
        INTERNAL_ERROR,
        ADD_CLASS_RESPONSE
    }

    /**
     * Response codes
     */
    export enum ResponseCode {
        OK_CODE,
        ERROR_CODE
    }

    /**
     * Packet of request
     */
    export abstract class RequestPacket {
        /**
         * Convert packet to binary data
         */
        abstract pack() : BinaryData;
    }

    /**
     * Response packet
     */
    export abstract class ResponsePacket {
        /**
         * Response id
         */
        id : ResponseType;

        /**
         * Response code
         */
        code : ResponseCode;

        /**
         * Unpack binary data to packet
         */
        static unpack(data : BinaryData) : ResponsePacket {
            let id = data.readUint8();
            let code = data.readUint8();

            if (code == ResponseCode.ERROR_CODE) {
                let errorCode = data.readUint8();
                return new ErrorResponse(id, errorCode);
            }

            let resp : ResponsePacket
            switch(id) {
                case ResponseType.ADD_CLASS_RESPONSE:
                    resp = AddClassResponse.unpack(data);
                    break;
            }

            if (resp == null) throw new Error("Unknown response");

            resp.id = id;
            resp.code = code;
            return resp;
        }
    }

    /**
     * Error response
     */
    export class ErrorResponse extends ResponsePacket {
        /**
         * Error code
         */
        errorCode : number;

        /**
         * Constructor
         * @param id 
         * @param errorCode 
         */
        constructor(id : ResponseType, errorCode : number) {
            super();
            this.id = id;
            this.code = ResponseCode.ERROR_CODE;
            this.errorCode = errorCode;
        }
    }

    /**
     * Add class request
     */    
    export class AddClassRequest extends RequestPacket {
        /**
         * Class name
         */
        name : string;

        /**
         * Parent id
         */
        parentId : string;

        /**
         * Constructor
         * @param name 
         * @param parentId 
         */
        constructor(name : string, parentId : string) {
            super();
            this.name = name;
            this.parentId = parentId;
        }

        /**
         * Convert packet to binary data
         */
        pack() : BinaryData {
            let bd = new BinaryData();
            bd.addUint8(RequestType.ADD_CLASS_REQUEST);
            bd.addStringWithLen(this.name);
            bd.addId(this.parentId);
            return bd;
        }
    }

    /**
     * Response for add class request
     */
    export class AddClassResponse extends ResponsePacket {
        /**
         * Class id
         */
        classId : string;

        static unpack(data : BinaryData) : AddClassResponse {
            let res = new AddClassResponse();
            res.classId = data.readId();
            return res;            
        }
    }
}