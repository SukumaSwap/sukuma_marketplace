// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;
//necessary imports not yet installed
import "@openzeppelin/upgradeable/contracts/access/OwnableUpgradeable.sol";
// Importing OpenZeppelin's ERC20 interface
import "@openzeppelin/upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IMarketplace} from "@contracts/IMarketplace.sol";

import {Pricefeed} from "@contracts/Pricefeed.sol";

contract Marketplace is
    Initializable,
    OwnableUpgradeable,
    IMarketplace,
    Pricefeed
{
    // Variables
    uint256 private marketplaceFee;
    //variable to count trades
    uint256 public tradeCounter = 0;
    // Variable to keep track of offerId
    uint256 public offerIdCounter;

    Pricefeed private pricefeed;

    bool releasedCrypto = false;

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
    mapping(address => Trade[]) public accountToTrades; //account address with an array of Trade objects

    // Initializer - replaces the constructor when using the upgradeable pattern
    function initialize(address _pricefeedAddress) external initializer {
        __Ownable_init();
        pricefeed = Pricefeed(_pricefeedAddress);
    }

    // Modifier

    // Functions
    function createAccount() external returns (uint256) {
        // Ensure account does not already exist
        /////to check////
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

    //function to create buy trade
    function createBuyTrade(uint256 offerId, uint256 quantity) external {
        // Input validators
        require(quantity > 0, "Quantity must be greater than zero");

        // Get the offer associated with the offerId
        Offer memory offer = offers[offerId];

        // Check if the offer exists
        require(offer.offerId == offerId, "OfferId does not exist");

        // Check if the token is the same as the offer token
        //to check/////
        require(
            offer.token == msg.sender,
            "Token address must be the same as the offer token"
        );

        // Check if the offer type is Sell
        require(offer.offerType == OfferType.Sell, "Offer type must be Sell");

        // Get the rate of the offer
        uint256 rate = offers[offerId].offerRate;

        // Calculate the trade amount
        uint256 convertedPrice = pricefeed.getPrice(
            quantity,
            offer.token,
            "USD"
        );
        uint256 tradeAmount = convertedPrice.mul(100 + rate).div(100);

        // Autogenerate tradeId
        tradeCounter++;
        uint256 tradeId = tradeCounter;

        // Create a new trade
        Trade memory trade = Trade({
            tradeId: tradeId,
            orderId: offerId,
            status: TradeStatus.Active,
            quantity: quantity,
            receiver: msg.sender,
            sender: offer.owner,
            token: offer.token,
            tradeType: TradeType.Buy,
            amount: tradeAmount
        });

        // Store the trade
        trades[tradeId] = trade;

        // Add the trade to the offerIdToTrades mapping
        offerIdToTrades[offerId].push(trade);

        // Add the trade to the accountToTrades mapping for both sender and receiver
        accountToTrades[offer.owner].push(trade);
        accountToTrades[msg.sender].push(trade);

        emit TradeCreated(tradeId, offerId, TradeType.Buy, TradeStatus.Active);
    }

    //function releaseCrypto
    function releaseCrypto(uint256 tradeId) external {
        // Fetch the required parameters from the createBuyTrade function
        uint256 quantity = trades[tradeId].quantity;
        address token = trades[tradeId].token;
        uint256 offerId = trades[tradeId].orderId;
        uint256 balance = accounts[trades[tradeId].sender].balance[token];
        // Check if the function is called by the address that created the sellOffer or sellTrade
        require(
            (msg.sender == offers[offerId].owner &&
                offers[offerId].offerType == OfferType.Sell) ||
                msg.sender == trades[tradeId].sender,
            "Only the creator of the sellOffer or sellTrade can call this function"
        );

        // Check if the parameters match the trade or offer
        require(
            receiver == trades[tradeId].receiver,
            "Receiver address does not match the trade"
        );
        require(
            quantity == trades[tradeId].quantity,
            "Quantity does not match the trade"
        );
        require(
            token == trades[tradeId].token,
            "Token address does not match the trade"
        );

        // Check if crypto has already been released
        require(!releasedCrypto, "Crypto has already been released");

        // Check if the sender has sufficient balance
        require(balance >= quantity, "Insufficient balance");

        // Update the account balances
        Account storage senderAccount = accounts[trades[tradeId].sender];
        // Account storage receiverAccount = accounts[receiver];
        senderAccount.balance[token] -= quantity;
        // receiverAccount.balance[token] += quantity;

        // Update the releasedCrypto bool
        releasedCrypto = true;

        // Add the trade to accountToTrades mapping
        accountToTrades[trades[tradeId].sender].push(trades[tradeId]);
        accountToTrades[receiver].push(trades[tradeId]);

        // Emit an event to indicate that the crypto has been released
        emit CryptoReleased(tradeId, receiver, quantity, token);

        // Transfer the crypto to the receiver's address/
        IERC20(token).transfer(receiver, quantity);
       
    }

    // Function to closeBuyTrade, can only be called by the creator of buyTrade
    function closeBuyTrade(uint256 tradeId) external {
        // Fetch the trade from the mapping
        Trade storage trade = trades[tradeId];

        // Check if the trade exists
        require(trade.orderId != 0, "Trade does not exist");

        // Check if the trade type is Buy
        require(trade.tradeType == TradeType.Buy, "TradeType must be Buy");

        // Check if the releaseCrypto function was called by the offer owner and offerType is Sell
        require(
            msg.sender == offers[trade.orderId].owner &&
                offers[trade.orderId].offerType == OfferType.Sell,
            "ReleaseCrypto function not called by offer owner or offerType is not Sell"
        );

        // Check if the crypto has been released
        require(releasedCrypto, "Crypto has not been released");

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

    //function to createSell
    function createSellTrade(uint256 offerId, uint256 quantity) external {
        // Input validators
        require(quantity > 0, "Quantity must be greater than zero");

        // Get the offer associated with the offerId
        Offer memory offer = offers[offerId];

        // Check if the offer exists
        require(offer.offerId == offerId, "OfferId does not exist");

        // Check if the token is the same as the offer token
        require(
            offer.token == msg.sender,
            "Token address must be the same as the offer token"
        );

        // Check if the offer type is Buy
        require(offer.offerType == OfferType.Buy, "Offer type must be Buy");

        // Get the rate of the offer
        uint256 rate = offers[offerId].offerRate;

        // Calculate the trade amount
        uint256 convertedPrice = pricefeed.getPrice(
            quantity,
            offer.token,
            "USD"
        );
        uint256 tradeAmount = convertedPrice.mul(100 + rate).div(100);

        // Autogenerate tradeId
        tradeCounter++;
        uint256 tradeId = tradeCounter;

        // Create a new trade
        Trade memory trade = Trade({
            tradeId: tradeId,
            orderId: offerId,
            status: TradeStatus.Active,
            quantity: quantity,
            receiver: offer.owner,
            sender: msg.sender,
            token: offer.token,
            tradeType: TradeType.Sell,
            amount: tradeAmount
        });

        // Store the trade
        trades[tradeId] = trade;

        // Add the trade to the offerIdToTrades mapping
        offerIdToTrades[offerId].push(trade);

        // Add the trade to the accountToTrades mapping for both sender and receiver
        accountToTrades[offer.owner].push(trade);
        accountToTrades[msg.sender].push(trade);

        emit TradeCreated(tradeId, offerId, TradeType.Buy, TradeStatus.Active);
    }

    //function to close sellTrade ,called by one who created the sellTrade
    function closeSellTrade(uint256 tradeId) external {
        // Fetch the trade from the mapping
        Trade storage trade = trades[tradeId];

        // Check if the trade exists
        require(trade.orderId != 0, "Trade does not exist");

        // Check if the trade type is Sell
        require(trade.tradeType == TradeType.Sell, "TradeType must be Sell");

        // Check if the releaseCrypto function was called by the address that created the sellTrade and offerType is Buy
        require(
            msg.sender == trades[tradeId].sender &&
                offers[trade.orderId].offerType == OfferType.Buy,
            "ReleaseCrypto function not called by address that created the sellTrade or offerType is not Buy"
        );

        // Check if the crypto has been released
        require(releasedCrypto, "Crypto has not been released");

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
        // Check if the sender is the creator of a sell trade and the trade status is active
        if (
            msg.sender == createSellTrade.sender &&
            createSellTrade.status == Status.Active
        ) {
            revert("Unauthorized access");
        }
        // Check if the sender is the creator of a sell offer and the account balance is equal to the minimum offer amount
        else if (
            msg.sender == createSellOffer.sender &&
            accounts[msg.sender].balance >= createSellOffer.minAmount
        ) {
            revert("Unauthorized access");
        } else {
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

//todos
//Note users shall ne inputing token quantity only system calculates for them price
//1. import and ing=herit pricefeed contractwell.
//2.test createbuy
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
// 10.check working of priceFeed initialized on function to initialize.
//11.Make sure to pass the address of the deployed Pricefeed contract when calling the createBuyTrade function.
