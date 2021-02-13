const CoinFlip = artifacts.require("CoinFlip");
const truffleAssert = require("truffle-assertions");

contract("CoinFlip", async function(accounts){

  it("should deploy properly with added balance", async function(){
    let instance = await CoinFlip.deployed( { from:accounts[1],value: web3.utils.toWei(".1", "ether")}) ;
    assert(await web3.eth.getBalance(instance.address) == web3.utils.toWei(".1", "ether"), "balance not set");
  });
  it("should not deploy properly", async function(){
    await truffleAssert.fails(CoinFlip.new());
  });
  it("should take input and return event", async function(){
    let instance = await CoinFlip.deployed();
    await instance.placeBet("1", {from: accounts[2], value: web3.utils.toWei(".1", "ether")});
    await truffleAssert.passes(instance.getPastEvents('Results',
    {
      filter:{player: web3.eth.getAccounts()},
      fromBlock:'latest'
    },function(error, _events){
      console.log(_events.events.Results.returnValues['_results'])}));
  });
  it("should deposit funds", async function(){
    let instance = await CoinFlip.new({from: accounts[1], value: web3.utils.toWei(".1", "ether")});
    await truffleAssert.passes(instance.Deposit({from: accounts[1],value: web3.utils.toWei(".1", "ether")
    })
  )});
  it("should get contract balance", async function(){
    let instance = await CoinFlip.deployed();
    await truffleAssert.passes(instance.getBalance());
  });
  it("should get user's balance", async function(){
    let instance = await CoinFlip.deployed();
    await truffleAssert.passes(instance.getBetterBalance());
  });
  it("should change ownership", async function(){
    let instance = await CoinFlip.new({from: accounts[4], value: web3.utils.toWei(".1", "ether")});
    await truffleAssert.passes(instance.changeOwner(accounts[1],{from: accounts[4]}));
    assert(await instance.owner() == accounts[1],"owner didn't change")
  });
  it("should withdraw funds if balance is present", async function(){
    let instance = await CoinFlip.deployed();

    for(var i = 0;i<4;i++){
    await instance.placeBet("1", {from: accounts[4],value: web3.utils.toWei(".1", "ether")})
    };

    if(await instance.getBetterBalance() != 0){
    await truffleAssert.passes(instance.withdrawRewards({from: accounts[4]}));
    }
  });
  it("should not allow the non-owner to withdraw contract balance", async function(){
    let instance = await CoinFlip.new({from: accounts[1], value: web3.utils.toWei(".1", "ether")});
    await truffleAssert.fails(instance.withdrawAll({from: accounts[3]}), truffleAssert.ErrorType.REVERT);
    await truffleAssert.passes(instance.withdrawAll({from: accounts[1]}));
  });
  it("should call update function and recieve callback function as a result", async function(){
    let insstance = await CoinFlip.deployed();
    await truffleAssert.passes(instance.update({from: account[1]}));


  });
});
