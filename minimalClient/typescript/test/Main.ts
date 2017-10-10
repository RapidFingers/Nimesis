/**
 * Start game when all dom loaded
 */
window.addEventListener('DOMContentLoaded', async () => {
    let client = new Utils.Client();
    await client.addClass("BaseClass", null);
});