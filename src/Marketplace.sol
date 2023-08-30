// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;
//necessary imports not yet installed
import "@openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
// Importing OpenZeppelin's ERC20 interface
import "@openzeppelin/upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IMarketplace} from "@contracts/IMarketplace.sol";

import "./Pricefeed.sol";
   
contract Marketplace is Initializable, OwnableUpgradeable, IMarketplace {
    // Variables
    uint256 private marketplaceFee;
    //variable to count trades
    uint256 public tradeCounter = 0;
    // Variable to keep track of offerId
    uint256 public offerIdCounter;
bool releasedCrypto = false;
bool receivedCrypto = false;

    // address public owner;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Trade) public trades;
    mapping(uint256 => Transfer) public transfers;
    // Mapping of wallet address to Account
    mapping(address => Account) private accounts;
    uint256 private nextAccountId = 1; // Account ID starts at 1
    // Mapping of accountId to Eth address
    mapping(uint256 => address) private idToAddress;
    mapping(uint256 => Trade[]) public offerIdToTrades; //mapping of offerId to associatedarray of Trade
    mapping(uint256 => Offer[]) public accountIdToOffers; //mapping of AccountId to All Offers Created by that Account.
mapping(address => Trade[]) public accountToTrades;//account address with an array of Trade objects


    // Initializer - replaces the constructor when using the upgradeable pattern
    function initialize() external initializer {
        __Ownable_init();
    }

    // Modifier

    // Functions
    function createAccount() external returns (uint256) {
        // Ensure account does not already exist
        require(
            accounts[msg.sender].walletAddress == address(0),
            "Account already exists"
        );
        // Create new account
        Account storage account = accounts[msg.sender];
        account.walletAddress = msg.sender;
        account.accountId = nextAccountId;

        // Store account ID to wallet address mapping
        idToAddress[nextAccountId] = msg.sender;
        // Emit event
        emit AccountCreated(msg.sender, nextAccountId);
        // Increment next account ID
        nextAccountId = nextAccountId + 1;
        return account.accountId;
    }

    // Function to get account information
    function getAccount(
        address walletAddress
    )
        external
        view
        returns (
            uint256 accountId,
            uint256 likes,
            uint256 dislikes,
            uint256 blocks
        )
    {
        Account storage account = accounts[walletAddress];
        return (
            account.accountId,
            account.likes,
            account.dislikes,
            account.blocks
        );
    }

    function createOffer(
        address _token,
        uint256 _quantity,
        OfferType _offerType,
        uint256 _min,
        uint256 _max,
        string memory _instructions,
        uint256 _offerRate,
        string[] memory _acceptedCurrency,
        string[] memory _paymentMethods

    ) external returns (uint256 offerId) {
        require(_token != address(0), "_token address cannot be zero");
        require(_quantity > 0, "_quantity must be greater than zero");

        uint balance = accounts[msg.sender].balance[_token];

        require(
            balance >= _quantity,
            "Insufficient balance ,please deposit first"
        );
        require(_min > 0, "min must be greater than zero");
        require(_max <= balance, "max must be less than or equal to balance");

        require(
            _acceptedCurrency.length > 0,
            "acceptedCurrency cannot be empty"
        );
        require(_paymentMethods.length > 0, "paymentMethods cannot be empty");

        // incrementing the offerIdCounter for each new offer
        offerIdCounter++;
// Getting the account ID of the owner
    uint256 accountId = accounts[msg.sender].accountId;
        // Creating a new offer
        offerId = offerIdCounter;

        Offer memory newOffer = Offer({
            owner: msg.sender,
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
            offerStatus: OfferStatus.Open
        });

        // Saving the offer in offers mapping
        offers[offerId] = newOffer;
        // Adding the offer to accountIdToOffers mapping
    accountIdToOffers[accountId].push(newOffer);

        emit OfferCreated(
            offerId,
            _token,
            _quantity,
            _offerType,
            _instructions,
            OfferStatus.Open
        );
    }

    function createBuyTrade(
        uint256 orderId,
        uint256 quantity,
        address receiver,
        address sender,
        address token,
        TradeType tradeType,
        uint64 amount
    ) external {
        //input validators
        require(token != address(0), "token address cannot be zero");
        require(quantity > 0, "quantity must be greater than zero");
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
            amount: amount
        });
        // Store the trade
        trades[tradeId] = trade;
        // Add the trade to the offerIdToTrades mapping
        offerIdToTrades[orderId].push(trade);
        // Add the trade to the accountToTrades mapping for both sender and receiver
    accountToTrades[sender].push(trade);
    accountToTrades[receiver].push(trade);

        emit TradeCreated(tradeId, orderId, tradeType, TradeStatus.Active);
    }
    
    //function to closeBuyTrde ,only be called by seller of Saleoffer
    function closeBuyTrade(uint256 tradeId) external {
        // Fetch the trade from the mapping
        Trade storage trade = trades[tradeId];

        // Check if the trade exists
        require(trade.orderId != 0, "Trade does not exist");

        // Check if the trade type is Buy
        require(trade.tradeType == TradeType.Buy, "TradeType must be Buy");

//commented out

        // Fetch the min and max quantity
        // (uint256 minQuantity, uint256 maxQuantity) = getQuantity(tradeId);

        // Check if the trade quantity is within the acceptable range
    //    commented out line 212 to 218

        // require(
        //     trade.quantity > 0 &&
        //         trade.quantity >= minQuantity &&
        //         trade.quantity <= maxQuantity,
        //     "Trade quantity is out of range"
        // );

        // Update the trade status to Completed
        trade.status = TradeStatus.Completed;

        // Emit the TradeClosed event
        emit TradeClosed(
            tradeId,
            trade.orderId,
            trade.tradeType,
            TradeStatus.Completed
        );
    }

    // Placeholder function to return min and max quantity
    // function getQuantity(
    //     uint256 tradeId
    // ) internal pure returns (uint256, uint256) {
    //     return (1, 100);
    // }

    function createSellTrade(
        uint256 orderId,
        uint256 quantity,
        address receiver,
        address sender,
        address token,
        TradeType tradeType,
        uint64 amount
    ) external {
        require(token != address(0), "token address cannot be zero");
        require(quantity > 0, "quantity must be greater than zero");
        // Require that the tradingType is Buy
        require(tradeType == TradeType.Sell, "TradeType must be Sell");
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
            amount: amount
        });
        // Store the trade
        trades[tradeId] = trade;
        // Add the trade to the offerIdToTrades mapping
        offerIdToTrades[orderId].push(trade);
        // Add the trade to the accountToTrades mapping for both sender and receiver
    accountToTrades[sender].push(trade);
    accountToTrades[receiver].push(trade);

        emit TradeCreated(tradeId, orderId, tradeType, TradeStatus.Active);
    }

    // Function to get the current marketplace fee
    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFee;
    }

    // Function to set the marketplace fee, can only be called by the contract owner
    function setMarketplaceFee(uint256 _fee) external onlyOwner {
        marketplaceFee = _fee;

        // Emitting an event when the marketplace fee is changed
        emit MarketplaceFeeChanged(_fee);
    }

    function deposit(address _token, uint256 _amount) external {
        // We use the ERC20 interface to interact with any ERC20 token
        IERC20 token = IERC20(_token);
        // Transfer the tokens to this contract
        bool success = token.transferFrom(msg.sender, address(this), _amount);

        // Ensure the transfer succeeded
        require(success, "Token transfer failed");
        // Update the account's balance
        accounts[msg.sender].balance[_token] += _amount;
        // Emit the Deposit event
        emit Deposit(_token, msg.sender, _amount);
    }

    //withdraw function
    function withdraw(address _token, uint256 quantity) external {
        // Ensure the user has enough tokens
        require(
            accounts[msg.sender].balance[_token] >= quantity,
            "Insufficient balance"
        );

        // Subtract the amount from the user's balance
        accounts[msg.sender].balance[_token] -= quantity;

        // Transfer the tokens from this contract to the user
        bool success = IERC20(_token).transfer(msg.sender, quantity);

        // Ensure the transfer succeeded
        require(success, "Token transfer failed");

        // Emit the withdrawal event
        emit Withdrawal(msg.sender, _token, quantity);
    }

    function checkBalance(
        address _account,
        address _token
    ) external view returns (uint256) {
        // Return the balance of the account
        return accounts[_account].balance[_token];
    }

//function to transfer crypto
    function transfer(address _token, uint256 _quantity, address _to) external {
        require(_quantity > 0, "Transfer quantity must be greater than zero");
        require(_to != address(0), "Receiver address cannot be zero address");

        // Ensure the user has enough tokens
        require(
            accounts[msg.sender].balance[_token] >= _quantity,
            "Insufficient balance"
        );

        // Subtract the amount from the user's balance
        accounts[msg.sender].balance[_token] -= _quantity;

        // IERC20(_token) allows the contract to interact with the ERC20 token at address _token
        IERC20 token = IERC20(_token);

        // Transfers _quantity amount of tokens to address _to
        // The contract must have enough tokens for the transfer to succeed
        bool success = token.transfer(_to, _quantity);

        // Ensure the transfer succeeded
        require(success, "Token transfer failed");

        // Update the balance of the receiver
        accounts[_to].balance[_token] += _quantity;

        // Emit TransferCreated event after successful transfer
        emit TransferCreated(_token, _to, _quantity);
    }

//function releaseCrypto   
function releaseCrypto(
    address receiver,
    uint256 quantity,
    address token,
    uint256 tradeId,
     uint256 offerId,
    uint256 balance
) external {
    // Check if the function is called by the address that created the sellOffer or sellTrade
    require(
        msg.sender == offers[offerId].owner && offers[offerId].offerType == OfferType.Sell|| msg.sender == trades[tradeId].sender,
        "Only the creator of the sellOffer or sellTrade can call this function"
    );

    // Check if the parameters match the trade or offer
    require(receiver == trades[tradeId].receiver, "Receiver address does not match the trade");
    require(quantity == trades[tradeId].quantity, "Quantity does not match the trade");
    require(token == trades[tradeId].token, "Token address does not match the trade");

    // Check if crypto has already been released
    require(!releasedCrypto, "Crypto has already been released");

    // Check if the sender has sufficient balance
    require(balance >= quantity, "Insufficient balance");

    // Update the account balances
    Account storage senderAccount = accounts[trades[tradeId].sender];
    // Account storage receiverAccount = accounts[receiver];
    senderAccount.balance[token] -= quantity;
    // receiverAccount.balance[token] += quantity;
//confirm if receiver balence can be updated given funds sent directly to their EOA;
   
    // Update the releasedCrypto bool
    releasedCrypto = true;

    // Add the trade to accountToTrades mapping
    accountToTrades[trades[tradeId].sender].push(trades[tradeId]);
    accountToTrades[receiver].push(trades[tradeId]);

    // Emit an event to indicate that the crypto has been released
    emit CryptoReleased(tradeId, receiver, quantity, token);

    // Transfer the crypto to the receiver's address
    IERC20(token).transfer(receiver, quantity);
}

//function receiveCrypto
function receiveCrypto(
    address receiver,
    uint256 quantity,
    address token,
    uint256 tradeId,
     uint256 offerId    
) external {
    // Check if the function is called by the address that created the buyOffer or buyTrade
    require(
        msg.sender == offers[offerId].owner && offers[offerId].offerType == OfferType.Buy || msg.sender == trades[tradeId].receiver,
        "Only the creator of the buyOffer or buyTrade can call this function"
    );
    // Update the receivedCrypto bool
    receivedCrypto = true;

    // Add the trade to accountToTrades mapping
    accountToTrades[trades[tradeId].sender].push(trades[tradeId]);
    accountToTrades[receiver].push(trades[tradeId]);

    // Emit an event to indicate that the crypto has been released
    emit CryptoReceived(tradeId, receiver, quantity, token);
    
}
    function closeOffer(uint256 _offerId) external {
        // Checking if the offer exists
        require(offers[_offerId].offerId == _offerId, "Offer does not exist");
        // Checking if the offer is not already closed
        require(
            offers[_offerId].offerStatus != OfferStatus.Closed,
            "Offer is already closed"
        );

        // ensure that the caller is the owner of the offer
        require(
            offers[_offerId].owner == msg.sender,
            "Only the owner can close the offer"
        );

        // Closing the offer
        offers[_offerId].offerStatus = OfferStatus.Closed;
        // Emitting the OfferClosed event
        emit OfferClosed(_offerId);
    }

    function like(uint256 _accountId) external {
        // Retrieve the wallet address associated with the account ID
        address accountAddress = idToAddress[_accountId];

        // Ensure the account exists
        require(accountAddress != address(0), "Account does not exist");

        // Increment the likes count for the account
        accounts[accountAddress].likes += 1;
    }

    function dislike(uint256 _accountId) external {
        // Retrieve the wallet address associated with the account ID
        address accountAddress = idToAddress[_accountId];

        // Ensure the account exists
        require(accountAddress != address(0), "Account does not exist");

        // Increment the likes count for the account
        accounts[accountAddress].dislikes += 1;
    }

    function blockAccount(uint256 _accountId) external {
        // Retrieve the wallet address associated with the account ID
        address accountAddress = idToAddress[_accountId];

        // Ensure the account exists
        require(accountAddress != address(0), "Account does not exist");

        // Increment the likes count for the account
        accounts[accountAddress].blocks += 1;
    }
}

//Recommendations:

// 1. Check the return value of `transferFrom` function in `deposit` function.[x]
// 2. Use the Checks-Effects-Interactions pattern in `withdraw` function.[x]
// 3. Add necessary input validation in your functions.[x]
// 4. Use modifiers to restrict access to functions.[x]
// 5. Emit events in all state-changing functions.[x]
// 6. Remove redundancy from your contract.[x]
// 7. Optimize gas usage where possible.[x]
// 8. Update your contract to use the latest functions provided by OpenZeppelin contracts.[x]
// 9.Function to getTradeQuantity [*]