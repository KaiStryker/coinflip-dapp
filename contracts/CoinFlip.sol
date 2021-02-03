pragma solidity 0.5.12;

contract CoinFlip {

address public owner;
mapping(address => uint) balance;

event DepositSent(address from, address to, uint amount);
event Results(address player, string _results);

constructor() public payable {
    require (msg.value == 1 ether, "deployment minimum not achieved");
    owner = msg.sender;
    }

modifier onlyOwner {

    require(msg.sender == owner, "Youre not the owner");
     _;
    }

modifier RequiredtoBet {

    require(msg.value >= 0.1 ether, "Minimum bet not placed");
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

    require (address(this).balance >= _balance);

    if (guess == block.timestamp%2){

      balance[msg.sender] += _balance;
      emit Results(msg.sender,"You win!");

      return true;
      }

    else if(guess != block.timestamp%2 && balance[msg.sender] != 0){

      balance[msg.sender] -= _balance;
      emit Results(msg.sender,"Sorry Try Again!");

      return false;
      }

    else

      emit Results(msg.sender,"Sorry Try Again!");
      return false;
    }

}
