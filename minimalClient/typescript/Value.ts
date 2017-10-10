namespace Utils {
    /**
     * Possible value types
     */
    export enum ValueType {
        INT,
        FLOAT,
        STRING
    }

    /**
     * Base class for value
     */
    export class Value {
    }

    /**
     * Int value
     */
    export class ValueInt extends Value {
        /**
         * Int value
         */
        value : number;
    }
}