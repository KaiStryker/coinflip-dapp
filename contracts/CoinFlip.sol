// SPDX-License-Identifier: MIT

pragma solidity 0.5.12;

import "./provableAPI.sol";
import { SafeMath } from "./SafeMath.sol";

// A simple coinFlip smart contract that utlizes 'Provable API' oracle for randomness
// Oracle docs: https://docs.provable.xyz
// Oracle GitHub: https://github.com/provable-things

contract CoinFlip is usingProvable{

//Utilization of OpenZeppelin SafeMath Library for added security
using SafeMath for uint;

//Keep track of owner
address public owner;

//Keep track of unclaimed funds of players
uint unclaimedFunds;

//Necessary parameter for update() function
uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

//Mapping of players and current games being played
mapping(address => Players) players;
mapping(bytes32 => Pending) playing;

//Events for contract
event LogNewProvableQuery(address player, string description);
event DepositSent(address from, address to, uint amount);
event Results(address player, uint256 result, string _results);
event UnclaimedGoods(string description);

//Logs players
struct Players {
      address player;
      uint betAmount;
      bool waiting;
      uint _balance;
      uint guess;
    }

//Logs current games
struct Pending{
      address _player;
      bytes32 id;

    }

//Sets ownership of contract, Provable Proof and takes initial deposit at deployment
constructor() public payable {
      require (msg.value == .1 ether, "Deployment minimum not achieved");
      owner = msg.sender;
      provable_setProof(proofType_Ledger);
    }

//Checks ownership
modifier onlyOwner {

      require(msg.sender == owner, "Youre not the owner");
       _;
    }

//Checks Bet requirement
modifier RequiredtoBet {

      require(msg.value >= 0.01 ether, "Minimum bet not placed");
       _;
    }

//Initiates bet, logs player's information and triggers update() function
function placeBet(uint guess) public payable RequiredtoBet returns (bool){

      uint _balance = msg.value.mul(2);

      require (address(this).balance >= _balance, "Balance not sufficient");
      require (players[msg.sender].waiting == false, "Currently in game");

      players[msg.sender].player = msg.sender;
      players[msg.sender].betAmount = msg.value.sub(provable_getPrice("random"));
      players[msg.sender].waiting = true;
      players[msg.sender].guess = guess;

      update();

      }

//Returns random number from Provable oracle and calls verifyFlip() function
function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public{
      require(msg.sender == provable_cbAddress());

      if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0){
      uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
      verifyFlip(randomNumber, _queryId);
      }
    }

//Checks for match between random number from oracle and player's guess
function verifyFlip(uint256 randomNumber, bytes32 _queryId) internal {

      Pending memory _bet = playing[_queryId];
      address _better = _bet._player;

      if(players[_better].guess == randomNumber){

      players[_better]._balance = players[_better]._balance.add(players[_better].betAmount.mul(2));

      unclaimedFunds += players[_better].betAmount.mul(2);
      emit Results(_better,randomNumber,"You win!");

      delete (playing[_queryId]);
      players[_better].betAmount = 0;
      players[_better].waiting = false;

      }
      else {

      emit Results(_better,randomNumber,"Sorry Try Again!");

      delete (playing[_queryId]);
      players[_better].betAmount = 0;
      players[_better].waiting = false;
      }
    }

//Sends request to Provable oracle
function update() internal {

      uint256 QUERY_EXECUTION_DELAY = 0;
      uint256 GAS_FOR_CALLBACK = 200000;
      bytes32 queryId = provable_newRandomDSQuery(
          QUERY_EXECUTION_DELAY,
          NUM_RANDOM_BYTES_REQUESTED,
          GAS_FOR_CALLBACK
          );

      playing[queryId].id = queryId;
      playing[queryId]._player = msg.sender;

      emit LogNewProvableQuery(msg.sender,"Flip taking place, stand by for results...");

    }

//Allows Owner to deposit funds to contract
function Deposit() public payable onlyOwner returns (uint){

      return address(this).balance;
    }

//Allows owner to withdraw funds not wrapped up in current games
function withdrawAll() public onlyOwner{

      msg.sender.transfer(address(this).balance - unclaimedFunds);

      if(unclaimedFunds > 0){
         emit UnclaimedGoods("Unclaimed Funds still available in contract");
      }
    }

//Allows players to withdraw rewards from successful games
function withdrawRewards() public {

      require(players[msg.sender]._balance > 0, "No available funds");

      uint _balance_ = players[msg.sender]._balance;
      msg.sender.transfer(_balance_);
      unclaimedFunds -= players[msg.sender]._balance;
      delete (players[msg.sender]);

      emit DepositSent(address(this),msg.sender, _balance_);
    }

//Returns balance of contract
function getBalance() public view returns (uint) {

      return address(this).balance;
    }

//Returns balance of player
function getBetterBalance() public view returns (uint) {

      return players[msg.sender]._balance;
    }

//Returns Address of contract
function getContractAddress() public view returns(address){

      return address(this);
    }

//Allows owner to transfer ownership of contract
function changeOwner(address newOwner) public onlyOwner returns (address){

      owner = newOwner;
      return owner;
    }

//Checks amount of funds unclaimed by players
function checkUnclaimedFunds() public view returns(uint){

      return unclaimedFunds;
    }

//Allows owner to destroy contract as long as there aren't any unclaimedFunds
function callitQuits() public onlyOwner{
      require(unclaimedFunds == 0);

      selfdestruct(msg.sender);
    }
}
