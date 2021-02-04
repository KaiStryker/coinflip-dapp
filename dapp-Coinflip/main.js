var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, "0x3C1d826fB39a6860fAec31FD3D85415a2C1fc006", {from:accounts[0],gas:500000,gasPrice:20000000000});
      console.log(contractInstance);
    });

    $("#add_bet_button").click(inputData);
    $("#get_reward_button").click(claimReward);
});

function inputData(){

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
  { filter:{player: web3.eth.getAccounts()},
    fromBlock:'latest'
  },(error, _events) => {
    if (error) throw("Error fetching events");
    console.log(_events); })).then(function(_events){
    $("#get_results_output").text(_events.events.Results.returnValues['_results']);
  });

}

function claimReward(){
 contractInstance.methods.withdrawRewards().send().then(function(res) {
         console.log(" Claim was successful")
         console.log(res);
       })

}




// function results(guess){
//   var res = contractInstance.methods.placeBet(guess).call();
//
//   contractInstance.methods.placeBet().call().then(function(res){
//   $("#get_results_output").text(res);
//   })
// }
//
