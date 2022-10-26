// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title A title that should describe the contract/interface
/// @author https://github.com/chirag-bgh
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

import "./AaveHelper.sol";

contract MaverickCore is AaveHandler{

    struct openPositions{

    }

    mapping(address => openPositions) private UserPosition;

    constructor() {

    }

    function openPosition(
        address _shorttoken,
        address _collateral,
        uint256 _amount0,
        uint256 _amount1
    ) public {

        uint256 maxBorrowAllowed = maxBorrowAllowedCalculate(_shorttoken,_collateral,_amount1);
        require(maxBorrowAllowed >= _amount0);

        // look up pool address
        

        // borrow from the pool
        IPool(poolAddress).borrow(_shorttoken, _amount0, 2, 0, msg.sender);

        // swap 
        swapAsset()

    }

    function closePosition{

    }


    function borrowAsset(
        address _shorttoken,
        address _collateral,
        uint256 _amount0,
        uint256 _amount
    ) private {

        // code

    }

    function increaePosition() public {

        //code
    }

    function decreasePosition() public {

        //code 
    }

    //uniswap

    function swapAssest() public {

        // code 

    }   

    function repayAssest() public {

        // code

    }





}