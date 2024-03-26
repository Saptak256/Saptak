// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();
error AlreadyFunded();

contract FundMe 
{
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => bool) private isFunder;
    address[] public funders;

    address public i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    constructor()
    {
        i_owner = msg.sender;
    }

    function fund() public payable 
    {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "More ETH needed!");
        require(!isFunder[msg.sender], "Address already funded");
        
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        isFunder[msg.sender] = true;
    }
    
    function getVersion() public pure returns (uint256)
    {
        return 0; // Placeholder function as Chainlink integration gets removed
    }
    
    modifier onlyOwner
    {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner 
   {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)
   {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
   }
        delete funders;
        // transfer
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function transferOwnership(address newOwner) public onlyOwner 
    {
        require(newOwner != address(0), "Invalid address");
        i_owner = newOwner;
    }

    fallback() external payable
    {
        fund();
    }

    receive() external payable 
    {
        fund();
    }
}