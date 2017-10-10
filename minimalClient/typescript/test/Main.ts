/**
 * Start game when all dom loaded
 */
window.addEventListener('DOMContentLoaded', async () => {
    let client = new Utils.Client();
    let id = await client.addClass("BaseClass", null);
});