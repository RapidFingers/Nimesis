/**
 * Start game when all dom loaded
 */
window.addEventListener('DOMContentLoaded', async () => {
    let gs = new Service.Client();    

    gs.onOpen = () => {
        console.log("OPENED");
        gs.getClassById(1505844713748267);
    }

    // gs.onPacket = (packet) => {
    //     console.log(packet);
    // }

    gs.open();
});