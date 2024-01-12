// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract DutchAuction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.

    // Current state of the auction.
    address payable public beneficiary;
    uint public auctionStartTime;
    uint public auctionEndTime;
    address public bidder;
    uint public bid_amount;

    // Data about the price
    // Must change over time, so we'll add a discount rate
    uint public startingPrice;
    uint public discountRate;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    /// Create a simple auction with `biddingTime` seconds bidding time on behalf of the
    /// beneficiary address `beneficiaryAddress`.
    constructor(
        uint biddingTime,
        address payable beneficiaryAddress,
        uint _startingPrice,
        uint _discountRate
    ) {
        beneficiary = beneficiaryAddress;
        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + biddingTime;
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        ended = false;
    }

    // This auction calculates the current price of the good offered at the auction
    // It is made such that the price decreases over time
    function getAuctionCurrentPrice() public view returns (uint) {
        uint discount = discountRate * (block.timestamp - auctionStartTime);
        return startingPrice - discount;
    }

    // To bid is to accept the price offered by the auctioneer.
    // This will effectively end the auction
    function bid() external payable {
        bidHelper();
    } 

    // Bidding here means that a bidder steps up and accepts the price
    // offered by the auctioneer, effectively ending the auction
    function bidHelper() public payable {

        // Revert the call if the auction period is over.
        if (ended)
            revert ("Auction has already ended");

        uint price = getAuctionCurrentPrice();
        if (msg.value >= price)
            revert ("ETH is bigger than the auction price.");
        
        // Assign the value and sender to the appropriate values
        bidder = msg.sender;
        bid_amount = msg.value;

        // Call the auctionEnd() function
        auctionEnd();
    }

    // Leave this here so that the user can end the auction at any time
    // Auction without impacting the user's wallet
    function endAuctionUser() external {
        ended = true;
    }

    // End the auction and send the highest bid to the beneficiary.
    function auctionEnd() public {
        if (ended)
            revert ("Auction has already been ended");

        // 2. Effects
        ended = true;
        
        // 3. Interaction
        beneficiary.transfer(bid_amount);
    }
}