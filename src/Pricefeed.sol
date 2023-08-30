// SPDX-License-Identifier: Apache-2.0
// This specifies the license under which the contract's code is released.
pragma solidity ^0.8.20;  // Specify the Solidity compiler version.

// import "./SafeMath.sol";  // Import the SafeMath library.

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";  // Import the Chainlink Price Feed interface.

contract Pricefeed {

    using SafeMath for uint256;  // Use the SafeMath library for safe mathematical operations.
    mapping(string => address) private priceFeeds;  // Mapping to store currency symbol => Price Feed address.

    // This function calculates the price of a given quantity of a token in a specific currency.
    function getPrice(uint256 _quantity, address _tokenAddress, string memory _currency) public view returns (uint256) {
        // Get the latest price from Chainlink price feed for the specified currency.
        (, int256 price, , , ) = getLatestPrice(_currency);

        // Get the decimals of the token.
        uint8 decimals = ERC20(_tokenAddress).decimals();

        // Calculate the price in USD.
        uint256 priceInUSD = uint256(price) * _quantity / (10**decimals);

        // Convert the price to the required currency.
        uint256 convertedPrice = convertCurrency(priceInUSD, "USD", _currency);

        return convertedPrice;
    }

    // This function converts an amount from one currency to another.
    function convertCurrency(uint256 _amount, string memory _fromCurrency, string memory _toCurrency) internal view returns (uint256) {
        // Get the address of the Chainlink Price Feed for the fromCurrency.
        AggregatorV3Interface fromPriceFeed = AggregatorV3Interface(priceFeeds[_fromCurrency]);

        // Get the address of the Chainlink Price Feed for the toCurrency.
        AggregatorV3Interface toPriceFeed = AggregatorV3Interface(priceFeeds[_toCurrency]);

        // Get the latest price of the fromCurrency.
        (, int256 fromPrice, , , ) = fromPriceFeed.latestRoundData();

        // Get the latest price of the toCurrency.
        (, int256 toPrice, , , ) = toPriceFeed.latestRoundData();

        // Calculate the conversion rate.
        uint256 conversionRate = uint256(fromPrice) * (10**18) / uint256(toPrice);

        // Convert the amount using the conversion rate.
        uint256 convertedAmount = (_amount * conversionRate) / (10**18);

        // Return the converted amount.
        return convertedAmount;
    }

    // This function returns an instance of the Chainlink Price Feed interface for a given currency.
    function getLatestPrice(string memory _currency) private view returns (AggregatorV3Interface) {
        // Get the address of the Chainlink Price Feed for the given currency.
        address priceFeedAddress = priceFeeds[_currency];

        // Return the Chainlink Price Feed interface.
        return AggregatorV3Interface(priceFeedAddress);
    }

    // This function sets the address of the Chainlink Price Feed for a given currency.
    function setPriceFeed(string memory _currency, address _priceFeedAddress) external {
        // Set the address of the Chainlink Price Feed for the given currency.
        priceFeeds[_currency] = _priceFeedAddress;
    }
}
