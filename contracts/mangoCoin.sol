pragma solidity ^0.4.4;

/*

This is the minter contract. Creates owner of MangoCoin.

*/
contract MangoSalad 
{
	address public owner;

	function MangoSalad() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) throw;
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
}

/*

MangoCoin Token

*/
contract mangoCoin is MangoSalad
{

	//creates an array with all balanaces 
	mapping(address => uint256) public balance;
	mapping(address => bool) public frozenAccounts;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	uint256 public sellPrice;
	uint256 public buyPrice;
	uint minBalanceForAccounts;

	function mangoCoin(uint256 initialSupply,string _name,uint8 _decimals,string _symbol,address _minter) 
	{
		if(_minter!=0)
			owner=_minter
		balance[msg.sender]=initialSupply;
		totalSupply=initialSupply;	
		name=_name;
		symbol=_symbol;
		decimals=_decimals;
		timeOfLastProof=now;
	}
	
	function mintToken(address target,uint256 mintedAmount) onlyOwner 
	{
		balance[target]+=mintedAmount;
		totalSupply+=mintedAmount;
		Transfer(0,owner,mintedAmount);
		Transfer(owner, target, mintedAmount);
	}

	function freezeAccount(address target,bool freeze) onlyOwner
	{
		frozenAccounts[target]=freeze;
		FrozenFunds(target,freeze);
	}

	function setPrices(uint256 _sellPrice, uint256 _buyPrice) onlyOwner
	{
		sellPrice=_sellPrice;
		buyPrice=_buyPrice;
	}

	function buy() payable returns (uint amount)
	{
		amount = msg.value / buyPrice;                     // calculates the amount
		if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
		balance[msg.sender] += amount;                   // adds the amount to buyer's balance
		balance[this] -= amount;                         // subtracts amount from seller's balance
		Transfer(this, msg.sender, amount);                // execute an event reflecting the change
		return amount;                                     // ends function and returns
	}

	function sell(uint amount) returns (uint revenue)
	{
		if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
		balance[this] += amount;                         // adds the amount to owner's balance
		balance[msg.sender] -= amount;                   // subtracts the amount from seller's balance
		revenue = amount * sellPrice;
		if (!msg.sender.send(revenue)) {                   // sends ether to the seller: it's important
			throw;                                         // to do this last to prevent recursion attacks
		} else {
			Transfer(msg.sender, this, amount);             // executes an event reflecting on the change
			return revenue;                                 // ends function and returns
	}

	function setMinBalance(uint minimumBalanceInFinney) onlyOwner 
	{
		minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
	}
	
	}
	function transfer(address _to, uint256 _value) {
		/* Check if sender has balance and for overflows */
		if (balance[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to])
			throw;

		if (frozenAccounts[msg.sender])
			throw;

		if (msg.sender.balance < minBalanceForAccounts)
			_to.send(sell((minBalanceForAccounts-msg.sender.balance)/sellPrice));

		/* Add and subtract new balances */
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		/* Notify anyone listening that this transfer took place */
		Transfer(msg.sender, _to, _value);
	}

	/* Proof of Work */
	bytes32 public currentChallenge;                         // The coin starts with a challenge
	uint public timeOfLastProof;                             // Variable to keep track of when rewards were given
	uint public difficulty = 10**32;                         // Difficulty starts reasonably low

	function proofOfWork(uint nonce)
	{
		bytes8 n = bytes8(sha3(nonce, currentChallenge));    // Generate a random hash based on input
		if (n < bytes8(difficulty)) throw;                   // Check if it's under the difficulty

		uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
		if (timeSinceLastProof <  5 seconds) throw;         // Rewards cannot be given too quickly
		balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;  // The reward to the winner grows by the minute

		difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  // Adjusts the difficulty

		timeOfLastProof = now;                              // Reset the counter
		currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number-1));  // Save a hash that will be used as the next proof
	}

	function giveBlockReward()
	{
		balance[block.coinbase]+=1;

	}

	function reward(uint answer, uint nextChallenge)
	{
		if(answer**3 != currentChallenge)
			throw;
		balance[msg.sender]+=1;
		currentChallenge=nextChallenge
	}

	//Events
	event Transfer(address indexed from, address indexed to, uint256 value);
	event FrozenFunds(address target, bool frozen);
}
