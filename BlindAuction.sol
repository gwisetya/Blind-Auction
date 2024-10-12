// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract BlindAuction{
    struct Bid{
        bytes32 blindedBid;
        uint256 deposit;
    }

    address payable beneficiary; 
    uint256 biddingEnd;
    uint256 revealEnd;
    bool ended; 
    mapping(address => Bid[]) addressToBids; 
    uint256 highestBid;
    address highestBidder; 

    event auctionEnded(address indexed highestBidder, uint256 highestBid); 

    constructor(address payable _beneficiary, uint256 _biddingDuration, uint256 _revealDuration){
        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _biddingDuration; 
        revealEnd = biddingEnd + _revealDuration; 
    }

    function bid(bytes32 _blindedBid) public payable{
        require(block.timestamp < biddingEnd, "bid ended");
        addressToBids[msg.sender].push(Bid({blindedBid: _blindedBid, deposit: msg.value})); 
    }

   function reveal(uint256[] calldata values, bool[] calldata fakes, bytes32[] calldata secrets) external {
    require(block.timestamp > biddingEnd && block.timestamp < revealEnd, "not reveal time");
        // Step 1: Validate lengths of input arrays 
    uint length = addressToBids[msg.sender].length;
    

    require(values.length == length, "Values length mismatch");
    require(fakes.length == length, "Fakes length mismatch");
    require(secrets.length == length, "Secrets length mismatch");


    // Step 2: Initialize a refund variable
    uint256 refund; 
    // Step 3: Loop through each bid
    for(uint i = 0 ; i < values.length; i++){
        Bid memory bidToCheck = addressToBids[msg.sender][i];
            // Step 4: Validate the hash against the blindedBid
        if(bidToCheck.blindedBid == keccak256(abi.encodePacked(values[i], fakes[i], secrets[i]))){
            if(!fakes[i] && bidToCheck.deposit >= values[i]){
                // Place the bid (we'll define placeBid separately)
                if (placeBid(msg.sender, values[i])) {
                    // If the bid is placed, reduce the refund by the bid value
                    refund += bidToCheck.deposit - values[i];
                } else {
                    // If the bid is not placed, refund the full deposit
                    refund += bidToCheck.deposit;
                }
            } else {
                // Step 5: Process valid bids and accumulate refunds
                refund += bidToCheck.deposit; 
            }
        }
        addressToBids[msg.sender][i].blindedBid = bytes32(0);
    }
    // Step 6: Transfer refunds to the sender
    (bool success, ) = payable(msg.sender).call{value: refund}("");
    require(success, "transaction not succesful"); 
    }

    function endAuction() public {
        require(ended == false, "Auction already ended");
        require(block.timestamp >= revealEnd, "Auction not ended yet");
        (bool success, ) = payable(beneficiary).call{value: highestBid}("");
        require(success, "transfer unsuccessful");
        ended = true; 
        emit auctionEnded(highestBidder, highestBid);
    }

    function placeBid(address _bidder, uint256 _bid) internal returns(bool){
        if(_bid > highestBid){
            if (highestBidder != address(0)) {
            (bool success, ) = payable(highestBidder).call{value: highestBid}("");
            require(success, "Refund failed"); // Ensure refund is successful
            } 
            highestBid = _bid;
            highestBidder = _bidder; 
            return true; 
        } else {
            return false;
        }
    }
}