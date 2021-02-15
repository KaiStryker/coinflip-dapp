var web3 = new Web3(Web3.givenProvider);
var contractInstance;
const _player = web3.eth.getAccounts();

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, "0xF29a7403f8F444319624cd8018E44ae56e7280AC", {from:accounts[0],gas:300000,gasPrice:20000000000});
      console.log(contractInstance);
    });

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

// Event Listeners

function ListeningForEvents(){
contractInstance.once('Results',
{ filter:{player: _player},
  fromBlock:'latest'
},(error, _events) => {
  if (error) throw("Error fetching events");
  console.log(_events);
  console.log(_events.events.Results.returnValues['player'])
})
}
// contractInstance.once('LogNewProvableQuery',
// { filter:{player: _player},
//   fromBlock:'latest'
// },(error, _events) => {
//   if (error) throw("Error fetching events");
//     showLoader(_events);
//   })

// Functions

function claimReward(){
 contractInstance.methods.withdrawRewards().send().then(function(res) {
  console.log(" Claim was successful")
  console.log(res);
       })
     }
