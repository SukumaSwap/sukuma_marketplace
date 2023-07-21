// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
    //necessary imports not yet installed
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
// Importing OpenZeppelin's ERC20 interface
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

import "openzeppelin/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SukumaMarketplace is Initializable, OwnableUpgradeable{
   //enums
    enum OfferType {Buy, Sell}
    enum OfferStatus {Open, Closed}
    enum TradeType {Buy, Sell}
    enum TradeStatus {Active, Disputed, Completed}
 // Structs
    struct Offer {
        uint256 offerId;
        address token;
        uint256 quantity;
        OfferType offerType;
        uint256 min;
        uint256 max;
        string instructions;
        uint256 offerRate;
        string[] acceptedCurrency;
        string[] paymentMethods;
        OfferStatus offerStatus;
    }

    struct Trade {
        uint256 tradeId;
        uint256 orderId;
        TradeStatus status;
        uint256 quantity; // token amount
        address receiver;
        address sender;
        address token;
        TradeType tradeType;
        uint64 amount;
    }

    struct Transfer {
        uint256 transferId;
        address token;
        uint256 quantity;
        address sender;
        address receiver;
    }

    struct Account {
        address walletAddress;
        uint64 accountId;
        uint256 likes;
        uint256 dislikes;
        uint256 Blocks;
        mapping(address => uint256) Balance; // Mapping of token to quantity
    }

    // Variables
    uint256 private marketplaceFee;
    // address public owner;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Trade) public trades;
    mapping(uint256 => Transfer) public transfers;
    // mapping(uint256 => Account) public accounts; //to be deleted

     // Mapping of wallet address to Account
    mapping(address => Account) private accounts;
    uint64 private nextAccountId = 1; // Account ID starts at 1

    // Events
    event OfferCreated(uint256 offerId);
    event TradeCreated(uint256 tradeId);
    event TransferCreated(uint256 transferId);
    event AccountCreated(address walletAddress, uint256 accountId);

     // Initializer - replaces the constructor when using the upgradeable pattern
       function initialize() public initializer {
        __Ownable_init();
    }


    // Modifier
   

    // Functions
    function createAccount() public returns (uint256) {
         // Ensure account does not already exist
        require(accounts[msg.sender].walletAddress == address(0), "Account already exists");
        // Create new account
        Account storage account = accounts[msg.sender];
        account.walletAddress = msg.sender;
        account.accountId = nextAccountId;
         // Emit event
        emit AccountCreated(msg.sender, nextAccountId);
         // Increment next account ID
        nextAccountId = nextAccountId+ 1;
         return account.accountId;
    }
  // Function to get account information
    function getAccount(address walletAddress) public view returns (uint256 accountId, uint256 likes, uint256 dislikes, uint256 Blocks) {
        Account storage account = accounts[walletAddress];
        return (account.accountId, account.likes, account.dislikes, account.Blocks);
    }
    
    // Variable to keep track of offerId
    uint256 public offerIdCounter;

    function createOffer(address _token,
        uint256 _quantity,
        OfferType _offerType,
        uint256 _min,
        uint256 _max,
        string memory _instructions,
        uint256 _offerRate,
        string[] memory _acceptedCurrency,
        string[] memory _paymentMethods,
        OfferStatus _offerStatus
        ) public   {
        // implementation goes here
         // incrementing the offerIdCounter for each new offer
        offerIdCounter = offerIdCounter+1;

         Offer memory newOffer = Offer({
            offerId: offerIdCounter,
            token: _token,
            quantity: _quantity,
            offerType: _offerType,
            min: _min,
            max: _max,
            instructions: _instructions,
            offerRate: _offerRate,
            acceptedCurrency: _acceptedCurrency,
            paymentMethods: _paymentMethods,
            offerStatus: _offerStatus
        });
// Saving the offer in offers mapping
        offers[offerIdCounter] = newOffer;
    }
//variable to count trades
  uint256 public tradeCounter = 0;

    function createBuyTrade( 
        uint256 orderId,
       
        uint256 quantity,
        address receiver,
        address sender,
        address token,
        TradeType tradeType,
        uint64 amount) public {
       
    // Require that the tradingType is Buy
        require(tradeType == TradeType.Buy, "TradeType must be Buy");
// Require that the offerId exists
        require(offers[orderId].offerId == orderId, "OfferId does not exist");
       // Autogenerate tradeId
        tradeCounter++;
        uint256 tradeId = tradeCounter; 
// Create a new trade
        Trade memory trade = Trade({
            tradeId: tradeId,
            orderId: orderId,
            status: TradeStatus.Active,
            quantity: quantity,
            receiver: receiver,
            sender: sender,
            token: token,
            tradeType: TradeType.Buy,
            amount:amount
        });
         // Store the trade
        trades[tradeId] = trade;
    }

    function createSellTrade(uint256 orderId,
       
        uint256 quantity,
        address receiver,
        address sender,
        address token,
        TradeType tradeType,
        uint64 amount) public {
       
    // Require that the tradingType is Buy
        require(tradeType == TradeType.Buy, "TradeType must be Buy");
// Require that the offerId exists
        require(offers[orderId].offerId == orderId, "OfferId does not exist");
       // Autogenerate tradeId
        tradeCounter++;
        uint256 tradeId = tradeCounter; 
// Create a new trade
        Trade memory trade = Trade({
            tradeId: tradeId,
            orderId: orderId,
            status: TradeStatus.Active,
            quantity: quantity,
            receiver: receiver,
            sender: sender,
            token: token,
            tradeType: TradeType.Sell,
            amount:amount
        });
         // Store the trade
        trades[tradeId] = trade;
    }

 // Event to emit when the marketplace fee is changed
    event MarketplaceFeeChanged(uint256 newFee);
// Function to get the current marketplace fee
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFee;
    }

     // Function to set the marketplace fee, can only be called by the contract owner
    function setMarketplaceFee(uint256 _fee) public onlyOwner {
        marketplaceFee = _fee;

        // Emitting an event when the marketplace fee is changed
        emit MarketplaceFeeChanged(_fee);
    }

    function deposit(address _token, uint256 _amount) public {
        // We use the ERC20 interface to interact with any ERC20 token
        IERC20 token = IERC20(_token);
        // Transfer the tokens to this contract
        token.transferFrom(msg.sender, address(this), _amount);
         // Update the account's balance
        accounts[msg.sender].Balance[_token] += _amount;

    }

// This event will be emitted when a user withdraws tokens
    event Withdrawal(address indexed user, address indexed token, uint256 amount);

   function withdraw(address _token, uint256 quantity) public {
        // Ensure the user has enough tokens
        require(accounts[msg.sender].Balance[_token] >= quantity, "Insufficient balance");

        // Subtract the amount from the user's balance
        accounts[msg.sender].Balance[_token] =accounts[msg.sender].Balance[_token] -= quantity;

        // Transfer the tokens from this contract to the user
        IERC20(_token).transfer(msg.sender, quantity);

        // Emit the withdrawal event
        emit Withdrawal(msg.sender, _token, quantity);
    }

   function checkBalance(address _account, address _token) external view returns (uint256) {
        // Return the balance of the account
         return accounts[_account].Balance[_token];
    }


    function transfer(address _token, uint256 _quantity, address _to) public { 
        require(_quantity > 0, "Transfer quantity must be greater than zero");
         require(_to != address(0), "Receiver address cannot be zero address");

        // IERC20(_token) allows the contract to interact with the ERC20 token at address _token
        IERC20 token = IERC20(_token);

        // Transfers _quantity amount of tokens to address _to
        // The contract must have enough tokens for the transfer to succeed
        token.transfer(_to, _quantity);
    }

// Define an event
event CryptoReleased(uint256 indexed tradeId, address token, uint256 quantity, address receiver);

  function releaseCrypto(address _token, uint256 _quantity, uint256 _tradeId, address _receiver, uint256 _balance) public {
    require(_balance >= _quantity, "Insufficient balance");

    // IERC20(_token) allows the contract to interact with the ERC20 token at address _token
    IERC20 token = IERC20(_token);

    // Transfer the tokens
    require(token.transfer(_receiver, _quantity), "Token transfer failed");

    // Update the balance
    _balance -= _quantity;

    // Emit an event for the token release
    emit CryptoReleased(_tradeId, _token, _quantity, _receiver);
}
// Event to be emitted when an offer is closed
    event OfferClosed(uint256 offerId);

    function closeOffer(uint256 _offerId) public {
     // Checking if the offer exists
        require(offers[_offerId].offerId == _offerId, "Offer does not exist");
          // Checking if the offer is not already closed
        require(offers[_offerId].offerStatus != OfferStatus.Closed, "Offer is already closed");
        // Closing the offer
        offers[_offerId].offerStatus = OfferStatus.Closed;
    }

    function like(uint256 _accountId) public {
        
    }

    function dislike(uint256 _accountId) public {
        // implementation goes here
    }

    // function block(uint256 _accountId) public {
    //     // implementation goes here
    // }
}
