the project is copied from "https://docs.soliditylang.org/en/latest/solidity-by-example.html#blind-auction"
however in the project they implemented a withdraw function to withdraw the funds of the outbid bidders
```
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `transfer` returns (see the remark above about
            // conditions -> effects -> interaction).
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }
```
They also used the pendingReturns mapping to keep track of all the funds that is outbid

in my project i immediately give back the funds when the placeBid funcion is called
```
function placeBid(address _bidder, uint256 _bid) internal returns(bool){
        if(_bid > highestBid){
            if (highestBidder != address(0)) {
            **(bool success, ) = payable(highestBidder).call{value: highestBid}("");**
            require(success, "Refund failed"); // Ensure refund is successful
            } 
            highestBid = _bid;
            highestBidder = _bidder; 
            return true; 
        } else {
            return false;
        }
    }
```

after asking chatgpt i immediately found my mistake:
Advantages:

    Simplicity: 
        This approach is straightforward, as funds are returned immediately during the bidding process.
    Less State Management: 
        You don't need an additional mapping to track pending returns since you process refunds immediately.

Disadvantages:

    Reentrancy Vulnerability: 
        If the previous highest bidder is a contract, they can execute code when receiving funds. 
        This can lead to reentrancy attacks, where an attacker could manipulate the contract state before the refund is processed. 
        Although you're using require to check for success, the state change occurs after the external call, which can still 
        leave your contract vulnerable if not handled properly.
    Gas Cost: 
        Each refund can increase the gas cost for the transaction, especially if there are many bidders, 
        as you process refunds in a single transaction.

However i will be keeping my mistakes here for future reference and i will not be deploying the contract anyways.
