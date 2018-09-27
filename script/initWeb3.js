var provider
// Is there is an injected web3 instance?
if (typeof web3 !== 'undefined') {
    provider = web3.currentProvider;
    web3 = new Web3(web3.currentProvider);
    console.log("Using injected web3.js")
} else {
    // If no injected web3 instance is detected, fallback to Ganache.
    provider = new web3.providers.HttpProvider('http://127.0.0.1:7545');
    web3 = new Web3(App.web3Provider);
    console.log("Falling back to Ganache")
}