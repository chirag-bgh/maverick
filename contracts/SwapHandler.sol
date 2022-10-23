// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwapHandler {
    /// @notice Params for swaps using SwapHub contract and swap handlers
    /// @param underlyingIn sold token address
    /// @param underlyingOut bought token address
    /// @param mode type of the swap: 0 for exact input, 1 for exact output
    /// @param amountIn amount of token to sell. Exact value for exact input, maximum for exact output
    /// @param amountOut amount of token to buy. Exact value for exact output, minimum for exact input
    /// @param exactOutTolerance Maximum difference between requested amountOut and received tokens in exact output swap. Ignored for exact input
    /// @param payload multi-purpose byte param. The usage depends on the swap handler implementation
    struct SwapParams {
        address underlyingIn;
        address underlyingOut;
        uint mode;                  // 0=exactIn  1=exactOut
        uint amountIn;              // mode 0: exact,    mode 1: maximum
        uint amountOut;             // mode 0: minimum,  mode 1: exact
        uint exactOutTolerance;     // mode 0: ignored,  mode 1: downward tolerance on amountOut (fee-on-transfer etc.)
        bytes payload;
    }

    /// @notice Execute a trade on the swap handler
    /// @param params struct defining the requested trade
    function executeSwap(SwapParams calldata params) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/// @notice Base contract for swap handlers
abstract contract SwapHandlerBase is ISwapHandler {
    function trySafeApprove(address token, address to, uint value) internal returns (bool, bytes memory) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))), data);
    }

    function safeApproveWithRetry(address token, address to, uint value) internal {
        (bool success, bytes memory data) = trySafeApprove(token, to, value);

        // some tokens, like USDT, require the allowance to be set to 0 first
        if (!success) {
            (success,) = trySafeApprove(token, to, 0);
            if (success) {
                (success,) = trySafeApprove(token, to, value);
            }
        }

        if (!success) revertBytes(data);
    }

    // function transferBack(address token) internal {
    //     uint balance = IERC20(token).balanceOf(address(this));
    //     if (balance > 0) Utils.safeTransfer(token, msg.sender, balance);
    // }

    function setMaxAllowance(address token, uint minAllowance, address spender) internal {
        uint allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < minAllowance) safeApproveWithRetry(token, spender, type(uint).max);
    }

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("SwapHandlerBase: empty error");
    }
}