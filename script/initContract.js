var TicTacToe
var gameCreatedEvent
var moveEvent
var ticTacToeNetwork

var contractLoadedPromise = new Promise(function(resolve, reject) {
  $.get('/build/contracts/TicTacToe.json',function(data) {
    //creating a contract object from the ABI contained in the json file
    var TicTacToeContract = web3.eth.contract(data.abi)
    //creating a contract instance from the contract address
    for (var item in data.networks) {
      ticTacToeNetwork = data.networks[item];
    }
    TicTacToe = TicTacToeContract.at(ticTacToeNetwork.address)
    
    //these two events are fired, respectively, when a game is creatd and when a move is made
    gameCreatedEvent = TicTacToe.GameCreated({}, "latest")
    moveEvent = TicTacToe.Move({}, "latest")
    
    //the resolve function calls the corresponding handler on every .then() waiting for this promise
    resolve();
  });
});