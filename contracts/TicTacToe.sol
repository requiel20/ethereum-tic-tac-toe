//The owner is player1
pragma solidity ^0.4.17;
    contract TicTacToe {
    
    uint8 constant BOARD_SIZE = 3;

    event GameCreated(
        address creator,
        int games
    );
    

    event Move(

    );
    
    mapping(address => address[]) opponentsMapping;

    mapping(address => Game[]) gameMapping;
    
    struct Game {
        address player1;
        address player2;
        bool ownerTurn;
        uint8 result;           // 0 for nothing, 1 for player1 wins, 2 for player2 wins, 3 for draw
        uint8[BOARD_SIZE][BOARD_SIZE] board;
        uint aliveTime;
        bool isClosed;
        uint prize;
    }

    function newGame(address opponent) public payable {
    if(opponent != msg.sender) {
        Game storage game;
        if(gameExist(msg.sender, opponent)) {
            game = getGameStructSlow(opponent);
            resetGame(game); //only succeed if game.isClosed == true
        } else {
            //the game does not exist can create
            gameMapping[msg.sender].push(Game(msg.sender, opponent, false, 0,
                [[0, 0, 0],[0, 0, 0],[0, 0, 0]], now, false, msg.value * 2));
            opponentsMapping[msg.sender].push(opponent);
            opponentsMapping[opponent].push(msg.sender);
            GameCreated(msg.sender, int256(gameMapping[msg.sender].length));
        }
    } else {
        //cannot create a game with yourself
        revert();
    }
  }

    function resetGame(Game storage game) private {
        assert(game.isClosed);
        game.ownerTurn = false;
        game.result = 0;
        game.board = [[0, 0, 0],[0, 0, 0],[0, 0, 0]];
        game.aliveTime = now;
        game.isClosed = false;
        game.prize = msg.value * 2;
  }

  function getGameIsClosed(address otherPlayer, bool owner) public view returns (bool) {
      Game storage game = getGameStruct(otherPlayer, owner);
      return game.isClosed;
  }

  function isGameClosable(address otherPlayer, bool owner) public view returns (bool) {
       Game storage game = getGameStruct(otherPlayer, owner);
      if(game.isClosed)
          return false;
      //if the game is finished, you can close the game
      if(game.result != 0) {
          return true;
      }

      //if no move has been made and you did not create this game, you can close the game
      if(isBoardEmpty(game) && owner == false) {
          return true;
      }

      //if the last move was more than 30 minutes ago and it's not your turn, you can close the game
      if(now - game.aliveTime > 30 minutes && ( ( (owner) && (!game.ownerTurn) ) || ( (!owner) && (game.ownerTurn) ) ) ) {
          return true;
      }

      return false;
  }

  function closeGame(address otherPlayer, bool owner) public {
      Game storage game = getGameStruct(otherPlayer, owner);
      assert(!game.isClosed);

      //if the game is finished, you can close the game
      if(game.result != 0) {
          game.isClosed = true;

          //nobody gets payed, the payment happens on the last move
          return;
      }

      //if no move has been made and you did not create this game, you can close the game
      if(isBoardEmpty(game) && owner == false) {
          game.isClosed = true;
          
          //only the owner gets back their ether, as no move has been made
          //and the other half of the prize was not received
          otherPlayer.transfer(game.prize / uint(2));
          return;
      }

      //if the last move was more than 30 minutes ago and it's not your turn, you can close the game
      if(now - game.aliveTime > 30 minutes && ( ( (owner) && (!game.ownerTurn) ) || ( (!owner) && (game.ownerTurn) ) ) ) {
          game.isClosed = true;

          //the prize is awarded to msg.sender, as the other player is considered withdrew
          msg.sender.transfer(game.prize);
          return;
      }
  }

  function isBoardEmpty(Game storage game) private view returns (bool) {
      for(uint i = 0; i < BOARD_SIZE; i ++) {
          for(uint j = 0; j < BOARD_SIZE; j ++) {
              if(game.board[i][j] != 0)
                return false;
          }
      }
      return true;
  }

  function gameExist(address player1, address player2) public view returns (bool) {
      for(uint i = 0; i < opponentsMapping[player1].length; i ++) {
          if(opponentsMapping[player1][i] == player2)
            return true;
      }
      return false;
  }

  function getOpponents() public view returns (address[]) {
      return opponentsMapping[msg.sender];
  }

  function getGameBoard(address otherPlayer, bool owner) public view returns (uint8[BOARD_SIZE][BOARD_SIZE]) {
    Game storage game = getGameStruct(otherPlayer, owner);
    return game.board;
  }
  
  function getGameStruct(address otherPlayer, bool owner) private view returns (Game storage) {
    Game[] storage games;
    if (owner) {
        games = gameMapping[msg.sender];
        for (uint i = 0; i < games.length; i++) {
            if (games[i].player1 == msg.sender && games[i].player2 == otherPlayer)
                return games[i];
        }
    } else {
        games = gameMapping[otherPlayer];
        for (uint j = 0; j < games.length; j++) {
            if ( games[j].player1 == otherPlayer && games[j].player2 == msg.sender)
                return games[j];
        }
    }
    
    assert(false);
  }

  function getGameBoardCopy(address otherPlayer)  public view returns (uint8[BOARD_SIZE * BOARD_SIZE + 1]) {
    Game storage game = getGameStructSlow(otherPlayer);
    uint8[BOARD_SIZE * BOARD_SIZE + 1] memory output;
    if(msg.sender == game.player1) {
        output[0] = 1;
    } else {
        output[0] = 2;
    }
    
    uint k = 1;
    for(uint i = 0; i < BOARD_SIZE; i ++) {
        for(uint j = 0; j < BOARD_SIZE; j ++) {
            output[k] = game.board[i][j];
            k ++;
        }
    }

    return output;
  }

  function getGameStructSlow(address otherPlayer) private view returns (Game storage) {
    Game[] storage games;
    games = gameMapping[msg.sender];
    for (uint i = 0; i < games.length; i++) {
        if (games[i].player1 == msg.sender && games[i].player2 == otherPlayer) {
            return games[i];
        }
    }
    games = gameMapping[otherPlayer];
    for (uint j = 0; j < games.length; j++) {
        if ( games[j].player1 == otherPlayer && games[j].player2 == msg.sender) {
            return games[j];
        }
    }
    revert();
  }

  /** 
    returns 
        0 on successufl move, nobody won yet
        1 on player1 victory
        2 on player2 victory
        3 on draw
        4 on error
  */
  function move(address otherPlayer, bool owner, uint8 i, uint8 j) public payable returns (uint8) {
    Game storage game = getGameStruct(otherPlayer, owner);


    uint8[BOARD_SIZE][BOARD_SIZE] storage board = game.board;

    //the first message must pay the prize
    if(isBoardEmpty(game) && msg.value != game.prize) {
        revert();
    }
    
    if(game.isClosed || game.result != 0 || ( (owner) && (!game.ownerTurn) ) || ( (!owner) && (game.ownerTurn) ) ) {
        return 4;
    }
    if(board[i][j] == 0) {
        if(owner) {
            board[i][j] = 1;
        } else {
            board[i][j] = 2;
        }
        game.ownerTurn = !game.ownerTurn;
        
        game.aliveTime = now;

        game.result = isGameFinished(game);

        if(game.result == 1) {
            if(owner) {
                msg.sender.transfer(game.prize);
            } else {
                otherPlayer.transfer(game.prize);
            }
        } else if(game.result == 2) {
            if(owner) {
                otherPlayer.transfer(game.prize);
            } else {
                msg.sender.transfer(game.prize);
            }
        } else if(game.result == 3) {
            otherPlayer.transfer(game.prize / 2);
            msg.sender.transfer(game.prize / 2);
        }

        return game.result;
    } 
    
    return 4;
  }
  
  function getGameResult(address otherPlayer, bool owner) public view returns (uint8) {
      Game storage game = getGameStruct(otherPlayer, owner);
      return game.result;
  }

  function getGameTurn(address otherPlayer, bool owner) public view returns (bool) {
      Game storage game = getGameStruct(otherPlayer, owner);
      return game.ownerTurn;
  }

  function getGamePrize(address otherPlayer, bool owner) public view returns (uint) {
      Game storage game = getGameStruct(otherPlayer, owner);
      return game.prize;
  }

  function getGameAliveTime(address otherPlayer, bool owner) public view returns (uint) {
      Game storage game = getGameStruct(otherPlayer, owner);
      return game.aliveTime;
  }
  

    /** 
        returns 
            0 on nobody won yet
            1 on player1 victory
            2 on player2 victory
            3 on draw
    */
    function isGameFinished(Game storage game) private view returns (uint8) {
        uint8[BOARD_SIZE][BOARD_SIZE] storage board = game.board;
        bool canBeDraw = true;
        for(uint8 i = 0; i < BOARD_SIZE; i ++) {
            //if row i or column i is all 1s, 1 wins
            if( (board[i][0] == 1 && board[i][1] == 1 && board[i][2] == 1) || 
                (board[0][i] == 1 && board[1][i] == 1 && board[2][i] == 1) )
                return 1;
            
            //if row i or column i is all 2s, 2 wins
            if( (board[i][0] == 2 && board[i][1] == 2 && board[i][2] == 2) || 
                (board[0][i] == 2 && board[1][i] == 2 && board[2][i] == 2) )
                return 2;
            
            //if a move can be stil made, the game is not a draw
            if( board[i][0] == 0 || board[i][1] == 0 || board[i][2] == 0 || 
                board[0][i] == 0 || board[1][i] == 0 || board[2][i] == 0 )
                canBeDraw = false;
        }
      
        //if one of the diagonals is all 1s, 1 wins
        if( (board[0][0] == 1 && board[1][1] == 1 && board[2][2] == 1) || 
            (board[0][2] == 1 && board[1][1] == 1 && board[2][0] == 1) )
            return 1;
            
        //if one of the diagonals is all 2s, 2 wins 
        if( (board[0][0] == 2 && board[1][1] == 2 && board[2][2] == 2) || 
            (board[0][2] == 2 && board[1][1] == 2 && board[2][0] == 2) )
            return 2;
            
        if(canBeDraw)
            return 3;
    }
}