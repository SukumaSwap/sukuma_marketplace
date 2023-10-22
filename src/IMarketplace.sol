// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IMarketplace {
    //enums
    enum OfferType {
        Buy,
        Sell
    }
    enum OfferStatus {
        Open,
        Closed
    }
    enum TradeType {
        Buy,
        Sell
    }

    enum TradeStatus {
        Active,
        Disputed,
        Completed
    }
    // Structs
    struct Offer {
        address owner;
        uint256 offerId;
        address token;
        uint256 quantity; // quantity to deposit to contract(max+gasfee)
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
        uint256 amount;
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
        uint256 blocks;
        mapping(address => uint256) balance; // Mapping of token to quantity
    }

    // Events
    event OfferCreated(
        uint256 offerId,
        address indexed token,
        uint256 quantity,
        OfferType offerType,
        string instructions,
        OfferStatus offerStatus
    );
    event TradeCreated(
        uint256 tradeId,
        uint256 orderId,
        TradeType tradeType,
        TradeStatus status
    );
    event TradeClosed(
        uint256 tradeId,
        uint256 orderId,
        TradeType tradeType,
        TradeStatus status
    );

    event TransferCreated(
        address indexed token,
        address indexed to,
        uint256 quantity
    );
    event AccountCreated(address walletAddress, uint256 accountId);

    // Event to be emitted when an offer is closed
    event OfferClosed(uint256 offerId);
    // Define an event
    event CryptoReleased(
        uint256 indexed tradeId,
        address token,
        uint256 quantity,
        address receiver
    );

    // event CryptoReceived(
    //     uint256 indexed tradeId,
    //     address token,
    //     uint256 quantity,
    //     address receiver
    // );

    // Event to emit when the marketplace fee is changed
    event MarketplaceFeeChanged(uint256 newFee);
    // This event will be emitted when a user withdraws tokens
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event Deposit(
        address indexed token,
        address indexed account,
        uint256 amount
    );
}
