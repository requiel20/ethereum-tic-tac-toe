var opponent;
var isOwner;
var BOARD_SIZE = 3;
var board = new Array(BOARD_SIZE);
for(i = 0; i < BOARD_SIZE; i ++) {
    board[i] = new Array(BOARD_SIZE);
}

$( document ).ready(function() {
    contractLoadedPromise.then(function(result) {
        getOpponents();
        var getOpponentsInterval = setInterval(function() {
            getOpponents();
        }, 1000);

        moveEvent.watch(function(error, result) {
            if(!error) {
                console.log("moveEvent watcher result: " + result);
            } else {
                console.log("Error on move event watcher");
            }
        })
    });
});

function newGame() {
    opponent = $('#newGameOpponent').val();
    prize = $("#newGamePrize").val();
    console.log("opponent for new game: " + opponent);
    console.log("prize for new game: " + prize)
    
    TicTacToe.newGame(opponent, { value: web3.toWei(prize , "ether")}, function(error, result) {
        if(result){
            console.log("newGameResult: " + result);
            getOpponents();

        } else {
            console.log(error);
        }
    })
}

function cancelGame() {
    console.log("cancelGame(): opponent: " + opponent + " isOwne: " + isOwner);
    TicTacToe.isGameClosable(opponent, isOwner, function(error, result) {
        if(!error) {
            console.log("game closable? " + result)
            TicTacToe.closeGame(opponent, isOwner, function(error, result) {

                if(!error) {
                    console.log("requested for closing game sent");
                } else {
                    console.log("error in closing game: " + error)
                }
            });
        } else {
            console.log("error in isGameClosable: " + error)
        }
    });
}

function searchGame() {
    opponent = $("#getGameOpponent").val();
    isOwner = $("#getGameOwner").val();
    updateGame();
}

function getOpponents() {
    TicTacToe.getOpponents.call(function(error, result) {
        if (!error) {
            $("#opponents").html("");
            var i = 0;
            for (const opponentItem of result) {
                $("#opponents").html($("#opponents").html() + 
                    "<div onclick=\"loadGame(" + i + ")\">" + opponentItem + "</div>\n");
                i ++;
            }
            //console.log("opponents: " + result);
            return result;
        } else {
            console.log("error on getOpponents: " + error);
            return error;
        }
    });
}

function loadGame(opponentIndex) {
    var updateGameInterval = setInterval(function() {
        updateGame();
    }, 1000);
    TicTacToe.getOpponents.call(function(error, result) {
        if (result) {
            var i = 0;
            for (const opponentItem of result) {
                if(i == opponentIndex) {
                    opponent = opponentItem;
                    isOwner = undefined;
                    updateGame();
                }
                i ++;
            }
        } else {
            console.log(error);
        }
    });
}

function move(i, j) {
    opponent = $("#opponentAddress").html();
    console.log("move at " + i + " " + j + " against opponent: " + opponent + ". isOwner= " + isOwner);
    var value;
    if(isBoardEmpty()) {
        value = parseInt($("#gamePrize").html());
    } else {
        value = 0;
    }
    
    TicTacToe.move(opponent, isOwner, i, j, {value : web3.toWei(value, "ether")}, function(error, result) {
        if(!error) {
            updateGame();
        } else {
            console.log("error in move: " + error);
        }
    });
}

function updateGame() {
    $("#opponentAddress").html(opponent);
    var loadGameBoardPromise = new Promise(loadGameBoard);
    loadGameBoardPromise.then(function result() {
        displayBoard();
        TicTacToe.getGameResult(opponent, isOwner, function(error, result) {
            if(!error) {
                var string;
                if(result == 0) {
                    string = "no";
                } else if (result == 1) {
                    if(isOwner) {
                        string = "yes, you won!";
                    } else {
                        string = "yes, you lost."
                    }
                } else if (result == 2) {
                    if(!isOwner) {
                        string = "yes, you won!";
                    } else {
                        string = "yes, you lost."
                    }
                } else if (result == 3){
                    string = "yes, it's a draw.";
                } else {
                    string = "";
                }
                $("#gameResult").html("" + string);
                var turn;
                if(result != "0") {
                    turn = "";
                    $("#gameTurn").html(turn);
                } else {
                    TicTacToe.getGameTurn(opponent, isOwner, function(error, result) {
                        if(!error) {
                            if(result) {
                                turn = 'x';
                            } else {
                                turn = 'o';
                            }
                            $("#gameTurn").html(turn);
                        } else {
                            console.log("error in get game turn: " + error);
                        }
                    })

                    TicTacToe.getGameAliveTime(opponent, isOwner, function(error, result) {
                        if(!error) {
                            var aliveTime = new Date(result * 1000);
                            $("#gameAliveTime").html("" + aliveTime);
                        } else {
                            console.log("error in get game aliveTime: " + error);
                        }   
                    });
                }

                TicTacToe.getGamePrize(opponent, isOwner, function(error, result) {
                    if(!error) {
                        $("#gamePrize").html("" + web3.fromWei(result, "ether"));
                    } else {
                        console.log("error in get game prize: " + error);
                    }   
                });

                TicTacToe.getGameIsClosed(opponent, isOwner, function(error, result) {
                    if(!error) {
                        var string;
                        if(result) {
                            string = "yes";
                        } else {
                            string = "no";
                        }
                        $("#gameIsClosed").html("" + string);
                    
                    } else {
                        console.log("error in get game isClosed: " + error);
                    }   
                })
            } else {
                console.log("error in get game result: " + error);
            }
        })
    }, function(error) {
        console.log("error in loadGameBoard promise return: " + error);
    });
}

function loadGameBoard(resolve, reject) {
    //console.log("opening game " + opponent + " " + isOwner);
    if (typeof isOwner !== 'undefined') {
        isOwner = isOwner;
        TicTacToe.getGameBoard(opponent, isOwner, function(error, result) {
            if (result) {
                var intBoard = toReadableBoard(result);
                //console.log("board: " + intBoard);
                board = toCharacterBoard(intBoard);
                resolve();
            } else {
                console.log("getBoardError: " + error);
                reject(error);
            }
        });
    } else {
        TicTacToe.getGameBoardCopy(opponent, function(error, result) {
            if (result) {
                console.log("isowner + board: " + result);
                if(result[0] == 1) {
                    console.log("You're the owner of the opened game")
                    isOwner = true;
                } else if (result[0] == 2) {
                    console.log("You're not the owner of the opened game")
                    isOwner = false;
                }
                var unreadableBoard = to2DBoard(result);
                var intBoard = toReadableBoard(unreadableBoard);
                board = toCharacterBoard(intBoard);
                resolve();
            } else {
                console.log("getBoardError: " + error);
                reject(error);
            }
        });
    }
}

function displayBoard() {
    if(isOwner) {
        $("#yourSymbol").html("x");
    } else {
        $("#yourSymbol").html("o");
    }
    for(i = 0; i < board.length; i ++) {
        for(j = 0; j < board.length; j ++) {
            var tdID = "#b" + i + j;
            $(tdID).html(board[i][j]);
        }
    }
    $("#openedGame").show();
}

function toCharacterBoard(intBoard) {
    for(i = 0; i < intBoard.length; i ++) {
        for(j = 0; j < intBoard[0].length; j ++) {
            intBoard[i][j] = toCharacter(intBoard[i][j]);
        }
    }
    return intBoard;
}

function toReadableBoard(unreadableBoard) {
    for(i = 0; i < unreadableBoard.length; i ++) {
        for(j = 0; j < unreadableBoard[0].length; j ++) {
            unreadableBoard[i][j] = toReadableInt(unreadableBoard[i][j]);
        }
    }
    return unreadableBoard;
}

function toReadableInt(uint) {
    return uint.c[0]
}

function toCharacter(int) {
    if(int == 0) {
        return ' ';
    } else if(int == 1) {
        return 'x';
    } else if(int == 2) {
        return 'o';
    } else {
        return 'E'
    }
}

function to2DBoard(array) {
    var k = 1;
    var output = new Array(BOARD_SIZE);
    for(i = 0; i < BOARD_SIZE; i ++) {
        output[i] = new Array(BOARD_SIZE);
    }

    for(i = 0; i < BOARD_SIZE ; i ++) {
        for(j = 0; j < BOARD_SIZE; j ++) {
            output[i][j] = array[k];
            k ++;
        }
    }
    return output;
}

function isBoardEmpty() {
    for(i = 0; i < BOARD_SIZE; i ++) {
        for(j = 0; j < BOARD_SIZE; j ++) {
            if(board[i][j] != " ")
                return false;
        }
    }
    return true;
}