// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStandardizedYield is IERC20Metadata {
    /// @dev Emitted whenever the exchangeRate is updated
    event ExchangeRateUpdated(uint256 oldExchangeRate, uint256 newExchangeRate);

    /// @dev Emitted when any base tokens is deposited to mint shares
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountSYOut
    );

    /// @dev Emitted when any shares are redeemed for base tokens
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountSYToRedeem,
        uint256 amountTokenOut
    );

    enum AssetType {
        TOKEN,
        LIQUIDITY
    }

    /// @dev Emitted when (`user`) claims their rewards
    event ClaimRewards(
        address indexed user,
        address[] rewardTokens,
        uint256[] rewardAmounts
    );

    /**
     * @notice mints an amount of shares by depositing a base token.
     * @param receiver shares recipient address
     * @param tokenIn address of the base tokens to mint shares
     * @param amountTokenToPull amount of base tokens to be transferred from (`msg.sender`)
     * @param minSharesOut reverts if amount of shares minted is lower than this
     * @return amountSharesOut amount of shares minted
     * @dev
     *
     * This contract receives base tokens using these two (possibly both) methods:
     * - The tokens have been transferred directly to this contract prior to calling deposit().
     * - Exactly `amountTokenToPull` are transferred to this contract using `transferFrom()` upon calling deposit().
     *
     * The amount of shares minted will be based on the combined amount of base tokens deposited
     * using the given two methods.
     *
     * Emits a {Deposit} event
     *
     * Requirements:
     * - (`baseTokenIn`) must be a valid base token.
     * - There must be an ongoing approval from (`msg.sender`) for this contract with
     * at least `amountTokenToPull` base tokens.
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut);

    /**
     * @notice redeems an amount of base tokens by burning some shares
     * @param receiver recipient address
     * @param amountSharesToPull amount of shares to be transferred from (`msg.sender`)
     * @param tokenOut address of the base token to be redeemed
     * @param minTokenOut reverts if amount of base token redeemed is lower than this
     * @return amountTokenOut amount of base tokens redeemed
     * @dev
     *
     * This contract receives shares using these two (possibly both) methods:
     * - The shares have been transferred directly to this contract prior to calling redeem().
     * - Exactly `amountSharesToPull` are transferred to this contract using `transferFrom()` upon calling redeem().
     *
     * The amount of base tokens redeemed based on the combined amount of shares deposited
     * using the given two methods
     *
     * Emits a {Redeem} event
     *
     * Requirements:
     * - (`tokenOut`) must be a valid base token.
     * - There must be an ongoing approval from (`msg.sender`) for this contract with
     * at least `amountSharesToPull` shares.
     */
    function redeem(
        address receiver,
        uint256 amountSharesToPull,
        address tokenOut,
        uint256 minTokenOut
    ) external returns (uint256 amountTokenOut);

    /**
     * @notice exchangeRateCurrent * scyBalance / 1e18 must return the asset balance of the account
     * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of scy
     he can mint must be X * exchangeRateCurrent / 1e18
     * @dev SCYUtils's assetToScy & scyToAsset should be used instead of raw multiplication
     & division
     *
     * May emit a {NewExchangeRate} event
     */
    function exchangeRateCurrent() external returns (uint256 res);

    /**
     * @notice returns the previously updated and stored shares exchange rate
     * @dev the returned value may be outdated if exchangeRateCurrent() was not called for a
     * extended period of time
     */
    function exchangeRateStored() external view returns (uint256 res);

    /**
     * @notice claims reward for (`user`)
     * @param user the user receiving their rewards
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     * @dev
     * Emits a `ClaimRewardss` event
     * See {getRewardTokens} for list of reward tokens
     */
    function claimRewards(
        address user
    ) external returns (uint256[] memory rewardAmounts);

    /**
     * @notice get the amount of unclaimed rewards for (`user`)
     * @param user the user to check for
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     */
    function accruedRewards(
        address user
    ) external view returns (uint256[] memory rewardAmounts);

    /**
     * @notice returns the list of reward token addresses
     */
    function getRewardTokens() external view returns (address[] memory);

    /**
     * @notice returns the address of the underlying yield token
     */
    function yieldToken() external view returns (address);

    /**
     * @notice returns a list of all the base tokens that can be deposited to mint shares
     */
    function getBaseTokens() external view returns (address[] memory res);

    /**
     * @notice checks whether a token is a valid base token
     * @notice returns a boolean indicating whether this is a valid token
     */
    function isValidBaseToken(address token) external view returns (bool);

    /**
    * @notice This function contains information to interpret what the asset is
    * @notice decimals is the decimals to format asset balances
    * @notice if asset is an ERC20 token, assetType = 0, assetAddress is the address of the token
    * @notice if asset is liquidity of an AMM (like sqrt(k) in UniswapV2 forks), assetType = 1,
    assetAddress is the address of the LP token
    * @notice assetDecimals is the decimals of the asset
    */
    function assetInfo()
        external
        view
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        );
}
