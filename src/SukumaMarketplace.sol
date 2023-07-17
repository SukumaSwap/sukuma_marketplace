// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract SukumaMarketplace is Initializable, OwnableUpgradeable{
    // Structs
    enum OfferType {Buy, Sell}
    enum OfferStatus {Open, Closed}
    enum TradeType {Buy, Sell}
    enum TradeStatus {Active, Disputed, Completed}

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
    mapping(uint256 => Account) public accounts;

    // Events
    event OfferCreated(uint256 offerId);
    event TradeCreated(uint256 tradeId);
    event TransferCreated(uint256 transferId);
    event AccountCreated(uint256 accountId);

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
        // implementation goes here
    }

    function createOffer(Offer memory _offer) public returns (uint256) {
        // implementation goes here
    }

    function createBuyTrade(Trade memory _trade) public returns (uint256) {
        // implementation goes here
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
