pragma solidity 0.5.12;
import "./provableAPI.sol";
import { SafeMath } from "./SafeMath.sol";

contract CoinFlip is usingProvable{

using SafeMath for uint;

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
    balance[address(this)].add(msg.value);
    provable_setProof(proofType_Ledger);
    }

modifier onlyOwner {

    require(msg.sender == owner, "Youre not the owner");
     _;
    }

modifier RequiredtoBet {

    require(msg.value >= 0.01 ether, "Minimum bet not placed");
     _;
    }

function placeBet(uint guess) public payable RequiredtoBet returns (bool){

    uint _balance = 2 * msg.value;
    Bet memory _bet = players[msg.sender];

    require (address(this).balance >= _balance, "Balance not sufficient");
    require (_bet.waiting == false);

    balance[address(this)].add(msg.value);
    bytes32 Id = update();

    Pending memory newPending;
    newPending.player = msg.sender;
    newPending.value = msg.value.sub(provable_getPrice("random"));
    newPending.guess = guess;
    playing[Id] = newPending;

    Bet memory newBet;
    newBet.player = msg.sender;
    newBet.value = msg.value.sub(provable_getPrice("random"));
    newBet.currentgame = Id;
    newBet.waiting = true;
    players[msg.sender] = newBet;

    }

function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public{
      require(msg.sender == provable_cbAddress());

      if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0){

      Bet memory _player = players[playing[_queryId].player];
      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      verifyFlip(randomNumber, _queryId);
      _player.waiting = false;

      delete (playing[_queryId]);

      }

    }

function verifyFlip(uint randomNumber, bytes32 _queryId) internal {

    Pending memory _bet = playing[_queryId];

    if(_bet.guess == randomNumber){

    balance[_bet.player].add(_bet.value.mul(2));
    balance[address(this)].sub(_bet.value.mul(2));

    emit Results(_bet.player,randomNumber,"You win!");
    }

    else if(_bet.guess != randomNumber && balance[_bet.player] != 0){

    balance[_bet.player].sub(_bet.value);

    emit Results(_bet.player,randomNumber,"Sorry Try Again!");
    }

    else{

    emit Results(_bet.player,randomNumber,"Sorry Try Again!");

        }

    }

function update() internal returns (bytes32){

    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
        );

    emit LogNewProvableQuery("Flip taking place, stand by for results...");
    return queryId;

    }

function Deposit() public payable onlyOwner returns (uint){

    balance[address(this)].add(msg.value);
    return address(this).balance;
    }

function withdrawAll() public onlyOwner returns (uint){
    require(address(this).balance == balance[address(this)]);

    uint oldBalance = address(this).balance;
    msg.sender.transfer(oldBalance);

    balance[address(this)].sub(oldBalance);

    assert(balance[address(this)] == address(this).balance);
    return address(this).balance;
    }

function withdrawRewards() public {

    require(balance[msg.sender] > 0);

    uint _balance = balance[msg.sender];
    uint previousSenderBalance = balance[msg.sender];

    msg.sender.transfer(_balance);
    emit DepositSent(address(this),msg.sender, _balance);

    balance[msg.sender].sub(_balance);

    assert(balance[msg.sender] == previousSenderBalance.sub(_balance));
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

}
