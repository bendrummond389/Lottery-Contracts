//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../node_modules/hardhat/console.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Token.sol";


contract Lottery is AccessControl {

    // access control role constants
    bytes32 private constant OWNER_ROLE = keccak256("OWNER");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN");

    // access control role variables
    uint8 public adminCount = 0;

    // lottery constants
    uint public constant BASIS_POINTS = 500;
    IERC20 public token;

    // lottery variables
    uint256 private ticketPrice = 20e18;
    uint256 public currentPool = 0;
    uint256 private collectedFees;
    address payable[] public players; // does this need to be payable?
    uint public lastDraw;

    // Events
    event Draw(address _winner, uint256 amount);

    constructor(IERC20 tokenAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender); 
        lastDraw = block.timestamp;
        token = tokenAddress;
    }
    
    function enterLottery(uint ticketQuantity) public payable {
        // calculate total price for tickets and request transfer from sender
        uint256 amount = (ticketPrice * ticketQuantity);
        token.transferFrom(msg.sender, address(this), amount);

        // calculate fees and add the rest of the received token to the pool
        calculateFees(amount);

        // add player to the ticket array
        for (uint i = 0; i < ticketQuantity; i++) {
            players.push(payable (msg.sender)); // does this need to be payable?
        }
    }

    function calculateFees(uint256 paymentReceived) private {
        uint fees = (paymentReceived / 10000) * BASIS_POINTS;
        currentPool += (paymentReceived - fees);
        collectedFees += fees;
    }

    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(address(this), block.timestamp)));
    }

    function draw() public onlyAdminOrOwner {
        // ensure lottery hasn't been drawn in the past hour
        require(block.timestamp >= (lastDraw + 300), "The lottery can only be drawn every 5 minutes.");

        // winner player
        uint index = getRandomNumber() % players.length;
        address winner = players[index];

        // transfer funds to winner
        token.transfer(winner, currentPool);

        emit Draw(winner, currentPool);

        // reset state of the contract
        players = new address payable[](0); // does this need to be payable?
        currentPool = 0;
        lastDraw = block.timestamp;
    }

    function addAdmin(address newAdmin) public onlyRole(OWNER_ROLE) {
        require(adminCount <= 2, "There are already 2 admin accounts for this contract");
        grantRole(ADMIN_ROLE, newAdmin);
        adminCount++;
    } 

    function removeAdmin(address removedAdmin) public onlyRole(OWNER_ROLE) {
        revokeRole(ADMIN_ROLE, removedAdmin);
        adminCount--;
    } 

    function changeTicketPrice(uint newPrice) public onlyRole(OWNER_ROLE) {
        ticketPrice = newPrice;
    }

    function getBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function withdrawlFees() public onlyRole(OWNER_ROLE) {
        token.transfer(msg.sender, collectedFees);
        
        // reset the collected fees
        collectedFees = 0;
    }

    modifier onlyAdminOrOwner {
        require (hasRole(OWNER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender));
        _;
    }
}
