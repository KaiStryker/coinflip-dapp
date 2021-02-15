var web3 = new Web3(Web3.givenProvider);
var contractInstance;
const _player = web3.eth.getAccounts();

//Connects metamask to DApp
$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, "0xF29a7403f8F444319624cd8018E44ae56e7280AC", {from:accounts[0],gas:300000,gasPrice:20000000000});
      console.log(contractInstance);
    });

    $("#add_bet_button").click(_Bet);
    $("#get_reward_button").click(claimReward);
});

//Function that triggers connection between player and contract
function _Bet(){
  $("#get_results_output").text("Pending Bet");
  var _guess = $("#HeadTails_input").val();

  if (_guess == "Heads" || _guess == "heads"){
    var guess = 0;
  }
  else if (_guess == "Tails" || _guess == "tails"){
  var guess = 1;
  }
  var bet = $("#betAmount_input").val();
  var config = {
    value: web3.utils.toWei(bet, "ether")
  }

  //Calls CoinFlip contract to initiate player's game
  contractInstance.methods.placeBet(guess).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  }).then(contractInstance.once('LogNewProvableQuery',
  { filter:{player: _player},
    fromBlock:'latest'
  },(error, _events) => {
    if (error) throw("Error fetching events");
    console.log(_events);
  })).then(function(_events){
    $("#get_results_output").text(_events.events.LogNewProvableQuery.returnValues['description'])}).then(function(res){
    ListeningForEvents();
  });

}

// Event Listener function
function ListeningForEvents(){
contractInstance.once('Results',
{ filter:{player: _player},
  fromBlock:'latest'
},(error, _events) => {
  if (error) throw("Error fetching events");
  console.log(_events);
  $("#get_results_output").text(_events.returnValues['_results'])
})
}

// Function that allows players to claim their rewards
function claimReward(){
 $("#get_results_output").text(" ");
 $("#claim_results").text("Claim pending");
 contractInstance.methods.withdrawRewards().send().on("transactionHash", function(hash){
   console.log(hash);
 }).once("confirmation", function(confirmationNr){
   console.log(confirmationNr);
  $("#claim_results").text("Claim was Successful") ;
 }).on("error", function(error){
     console.log(error);
     $("#claim_results").text("Claim Failed, Check Balance");
     })
