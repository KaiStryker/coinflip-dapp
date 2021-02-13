var web3 = new Web3(Web3.givenProvider);
var contractInstance;
var _player;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, "0x985C04AEd2aC00Aa0204851fC3183F0aa53078A3", {from:accounts[0],gas:500000,gasPrice:20000000000});
      console.log(contractInstance);
    });

    _player = web3.eth.getAccounts();

    $("#add_bet_button").click(_Bet);
    $("#get_reward_button").click(claimReward);
});

function _Bet(){
  var _guess = $("#HeadTails_input").val();

  if (_guess == "Heads" || _guess == "heads"){
    var guess = 0;
  }
  var guess = 1;
  var bet = $("#betAmount_input").val();
  var config = {
    value: web3.utils.toWei(bet, "ether")
  }

  contractInstance.methods.placeBet(guess).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  }).then(contractInstance.once('Results',
  { filter:{player: _player},
    fromBlock:'latest'
  },(error, _events) => {
    if (error) throw("Error fetching events");
    console.log(_events); })).then(function(_events){
    $("#get_results_output").text(_events.events.Results.returnValues['_results']);
  });
}

// Event Listeners

contractInstance.once('Results',
{ filter:{player: _player},
  fromBlock:'latest'
},(error, _events) => {
  if (error) throw("Error fetching events");
  console.log(_events); }).then(function(_events){
  var __results = _events.events.Results.returnValues['_results']}.then( __results => {
    showResults(__results);
  }));

contractInstance.once('LogNewProvableQuery',
{ filter:{player: _player},
  fromBlock:'latest'
},(error, _events) => {
  if (error) throw("Error fetching events");
    showLoader(_events);
  });

// Functions

function claimReward(){
 contractInstance.methods.withdrawRewards().send().then(function(res) {
  console.log(" Claim was successful")
  console.log(res);
       });
}

function showLoader(_event) {
  document.getElementById("loader").style.display = "block";
  $("#get_output").text(_event.events.Results.returnValues['_results']);
}

function hideLoader(){
  document.getElementById("loader").style.display = "none";
}

function showResults(__results){
  hideLoader();

  if (__results == "You win!"){
    document.getElementById("Congrats").style.display = "block";
  }
  else {
    document.getElementById("Sorry").style.display = "block";
  }
}
