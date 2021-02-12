pragma solidity 0.5.12;
import "./provableAPI.sol";

contract CoinFlip is usingProvable{

address public owner;
mapping(address => uint) balance;

uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
uint256 private latestNumber;

mapping(address => Bet) players;
mapping(bytes32 => Pending) playing;

event LogNewProvableQuery(string description);
event DepositSent(address from, address to, uint amount);
event Results(address player, uint256 result, string _results);

struct Bet {
  address player;
  uint value;
  bytes32 currentgame;
  bool waiting;
}

struct Pending{
  address player;
  uint value;
  uint guess;
}

constructor() public payable {
    require (msg.value == .1 ether, "deployment minimum not achieved");
    owner = msg.sender;
    balance[address(this)] += msg.value;
    }

modifier onlyOwner {

    require(msg.sender == owner, "Youre not the owner");
     _;
    }

modifier RequiredtoBet {

    require(msg.value >= 0.01 ether, "Minimum bet not placed");
     _;
    }

function Deposit() public payable onlyOwner returns (uint){

    return address(this).balance;
    }

function getBalance() public view returns (uint) {

    return address(this).balance;
    }

function getBetterBalance() public view returns (uint) {

    return balance[msg.sender];
    }

function getContractAddress() public view returns(address){

    return address(this);
    }

function changeOwner(address newOwner) public onlyOwner returns (address){

    owner = newOwner;
    return owner;
    }

function withdrawAll() public onlyOwner returns (uint){
    require(address(this).balance == balance[address(this)]);

    msg.sender.transfer(address(this).balance);
    return address(this).balance;
    }

function withdrawRewards() public {

    require(balance[msg.sender] > 0);

    uint _balance = balance[msg.sender];
    uint previousSenderBalance = balance[msg.sender];

    msg.sender.transfer(_balance);
    emit DepositSent(address(this),msg.sender, _balance);

    balance[msg.sender] -= _balance;

    assert(balance[msg.sender] == previousSenderBalance - _balance);
    }

function placeBet(uint guess) public payable RequiredtoBet returns (bool){

    uint _balance = 2 * msg.value;
    Bet memory _bet = players[msg.sender];

    require (address(this).balance >= _balance, "Balance not sufficient");
    require (_bet.waiting == false);

    bytes32 Id = update();

    Pending memory newPending;
    newPending.player = msg.sender;
    newPending.value = msg.value;
    newPending.guess = guess;
    playing[Id] = newPending;

    Bet memory newBet;
    newBet.player = msg.sender;
    newBet.value = msg.value;
    newBet.currentgame = Id;
    newBet.waiting = true;
    players[msg.sender] = newBet;

    }

function __callback(bytes32 _queryId, string memory _result) public{
      require(msg.sender == provable_cbAddress());

      Pending memory _bet = playing[_queryId];
      Bet memory _player = players[_bet.player];

      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      latestNumber = randomNumber;
      _player.waiting = false;

     if(_bet.guess == latestNumber){

      balance[_bet.player] += (_bet.value *2);
      balance[address(this)]-=(_bet.value*2);

      emit Results(_bet.player,latestNumber,"You win!");
     }

     else if(_bet.guess != latestNumber && balance[_bet.player] != 0){

      balance[_bet.player] -= _bet.value;
      balance[address(this)]+=(_bet.value);

      emit Results(_bet.player,latestNumber,"Sorry Try Again!");
     }

     else{

      balance[address(this)]+=(_bet.value);
      emit Results(_bet.player,latestNumber,"Sorry Try Again!");
     }

      delete (playing[_queryId]);
    }

function update() internal returns (bytes32){

      uint256 QUERY_EXECUTION_DELAY = 0;
      uint256 GAS_FOR_CALLBACK = 200000;
      bytes32 queryId = provable_newRandomDSQuery(
          QUERY_EXECUTION_DELAY,
          NUM_RANDOM_BYTES_REQUESTED,
          GAS_FOR_CALLBACK
      );

      emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
      return queryId;

    }
}
