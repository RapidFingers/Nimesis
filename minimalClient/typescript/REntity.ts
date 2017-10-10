namespace Utils {
    /**
     * Referrence class entity
     */
    export abstract class REntity {
        /**
         * Entity id
         */
        id : number;

        /**
         * Entity name
         */
        name : string;

        /**
         * Constructor
         */
        constructor() {

        }
    }

    /**
     * Referrence class entity
     */
    export class RClass extends REntity {
        /**
         * Constructor
         */
        constructor() {
            super();
        }
    }

    /**
     * Referrence instance entity
     */
    export class RInstance extends REntity {
    }
}