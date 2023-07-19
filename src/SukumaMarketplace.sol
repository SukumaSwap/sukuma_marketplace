// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/acess/OwnableUpgradable.sol";

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// Importing OpenZeppelin's SafeMath for safe mathematical operations
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";


    //necessary imports not yet installed
import "@openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
// Importing OpenZeppelin's ERC20 interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
        uint256 Min;
        uint256 Max;
        string instructions;
        uint256 OfferRate;
        string[] acceptedCurrency;
        string[] paymentMethods;
        OfferStatus offerStatus;
    }

    struct Trade {
        uint256 tradeId;
        uint256 orderId;
        TradeStatus status;
        uint256 quantity;
        address receiver;
        address sender;
        address token;
        TradeType tradingType;
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
        uint256 accountId;
        uint256 likes;
        uint256 dislikes;
        uint256 Blocks;
        mapping(address => uint256) Balance; // Mapping of token to quantity
    }

    // Variables
    uint256 public marketplaceFee;
    address public owner;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Trade) public trades;
    mapping(uint256 => Transfer) public transfers;
    // mapping(uint256 => Account) public accounts; to be deleted

     // Mapping of wallet address to Account
    mapping(address => Account) private accounts;
    uint256 private nextAccountId = 1; // Account ID starts at 1

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
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

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
        nextAccountId = nextAccountId.add(1);
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
        offerIdCounter = offerIdCounter.add(1);
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

    function createBuyTrade( uint256 tradeId,
        uint256 orderId,
        TradeStatus status,
        uint256 quantity,
        address receiver,
        address sender,
        address token,
        TradeType tradingType) public {
       
    // Require that the tradingType is Buy
        require(tradingType == TradeType.Buy, "TradeType must be Buy");
// Require that the offerId exists
        require(offers[orderId].offerId == orderId, "OfferId does not exist");
        
    }

    function createSellTrade(Trade memory _trade) public returns (uint256) {
        // implementation goes here
    }

    function setmarketplaceFee(uint256 _fee) public onlyOwner {
        // implementation goes here
    }

    function deposit(address _token, uint256 _amount) public {
        // implementation goes here
    }

    function withdraw(address _token, uint256 _amount) public {
        // implementation goes here
    }

    function checkBalance(address _token) public view returns (uint256) {
        // implementation goes here
    }

    function transfer(address _token, uint256 _amount, address _to) public {
        // implementation goes here
    }

    function releaseCrypto(uint256 _quantity, uint256 _tradeId, address _receiver, uint256 _balance) public {
        // implementation goes here
    }

    function closeOffer(uint256 _offerId) public {
        // implementation goes here
    }

    function like(uint256 _accountId) public {
        // implementation goes here
    }

    function dislike(uint256 _accountId) public {
        // implementation goes here
    }

    // function block(uint256 _accountId) public {
    //     // implementation goes here
    // }
}
