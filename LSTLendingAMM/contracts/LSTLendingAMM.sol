// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title LST Lending AMM with Collateralized Swaps
contract LSTLendingAMM is ReentrancyGuard, AccessControl {
    // Define roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    
    address public treasury;
    bool public paused;
    uint256 public minHealthFactor = 1e18; // Minimum health factor for safe positions
    uint256 public borrowCooldown = 1 days; // Time between consecutive borrowings

    // Token interfaces
    IERC20 public lstToken;
    IERC20 public borrowToken;

    // Oracle interface
    AggregatorV3Interface public priceFeed;

    // Protocol Stats
    uint256 public totalCollateral;
    uint256 public totalBorrowed;

    // User Accounts
    struct CollateralAccount {
        uint256 collateralAmount;
        uint256 lastBorrowTimestamp;
    }

    struct DebtAccount {
        uint256 debtAmount;
    }

    mapping(address => CollateralAccount) public collateralAccounts;
    mapping(address => DebtAccount) public debtAccounts;

    // Events
    event CollateralDeposited(address indexed user, uint256 amount);
    event AssetBorrowed(address indexed user, uint256 amount);
    event PositionLiquidated(address indexed borrower, address indexed liquidator, uint256 amount);
    event TreasuryFunded(address indexed sender, uint256 amount);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Protocol paused");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier onlyLiquidator() {
        require(hasRole(LIQUIDATOR_ROLE, msg.sender), "Not liquidator");
        _;
    }

    modifier cooldownNotElapsed() {
        require(
            block.timestamp >= collateralAccounts[msg.sender].lastBorrowTimestamp + borrowCooldown,
            "Cooldown period has not elapsed"
        );
        _;
    }

    constructor(
        address _lstToken,
        address _borrowToken,
        address _priceFeed,
        address _treasury
    ) {
     //   _setupRole(ADMIN_ROLE, msg.sender);
    //    _setupRole(LIQUIDATOR_ROLE, msg.sender);
         _grantRole(ADMIN_ROLE, msg.sender);
         _grantRole(LIQUIDATOR_ROLE, msg.sender);
        treasury = _treasury;

        lstToken = IERC20(_lstToken);
        borrowToken = IERC20(_borrowToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice Deposit LST as collateral
    function depositCollateral(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer LST tokens from user to contract
        require(lstToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update collateral account
        collateralAccounts[msg.sender].collateralAmount += amount;
        totalCollateral += amount;

        emit CollateralDeposited(msg.sender, amount);
    }

    /// @notice Borrow assets using LST collateral
    function borrow(uint256 borrowAmount) external whenNotPaused cooldownNotElapsed {
        require(borrowAmount > 0, "Borrow amount must be greater than 0");

        uint256 lstValueInUSD = getCollateralValue(msg.sender);
        uint256 requiredCollateral = borrowAmount * 2; // 200% collateralization

        require(lstValueInUSD >= requiredCollateral, "Insufficient collateral");

        // Calculate interest rate (simple logic)
        uint256 utilization = (totalBorrowed * 100) / totalCollateral;
        uint256 interestRate = calculateInterestRate(utilization);
        uint256 debtAmount = borrowAmount + (borrowAmount * interestRate / 100);

        // Transfer borrowed tokens to user
        require(borrowToken.transfer(msg.sender, borrowAmount), "Borrow transfer failed");

        // Update user debt and protocol stats
        debtAccounts[msg.sender].debtAmount += debtAmount;
        totalBorrowed += borrowAmount;
        collateralAccounts[msg.sender].lastBorrowTimestamp = block.timestamp;

        emit AssetBorrowed(msg.sender, borrowAmount);
    }

    /// @notice Liquidate under-collateralized positions
    function liquidate(address borrower, uint256 repayAmount) external whenNotPaused onlyLiquidator nonReentrant {
        require(repayAmount > 0, "Repay amount must be greater than 0");

        uint256 lstValueInUSD = getCollateralValue(borrower);
        uint256 debtValue = debtAccounts[borrower].debtAmount;

        uint256 healthFactor = calculateHealthFactor(lstValueInUSD, debtValue);
        require(healthFactor < minHealthFactor, "Position still safe");

        uint256 liquidationAmount = repayAmount < debtValue ? repayAmount : debtValue;

        // Swap borrowed assets for collateral
        require(
            lstToken.transfer(msg.sender, liquidationAmount),
            "Liquidation transfer failed"
        );

        // Treasury fee (10%)
        uint256 treasuryFee = liquidationAmount / 10;
        require(
            lstToken.transfer(treasury, treasuryFee),
            "Treasury transfer failed"
        );

        debtAccounts[borrower].debtAmount -= liquidationAmount;
        collateralAccounts[borrower].collateralAmount -= liquidationAmount;

        // Liquidation bonus (1%)
        uint256 liquidationBonus = liquidationAmount / 100;
        require(
            lstToken.transfer(msg.sender, liquidationBonus),
            "Bonus transfer failed"
        );

        emit PositionLiquidated(borrower, msg.sender, liquidationAmount);
    }

    /// @notice Fetch collateral value in USD
    function getCollateralValue(address user) public view returns (uint256) {
        uint256 lstAmount = collateralAccounts[user].collateralAmount;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        return lstAmount * uint256(price) / 1e8; // Assuming oracle has 8 decimals
    }

    /// @notice Calculate health factor
    function calculateHealthFactor(uint256 collateralValue, uint256 debtValue) public pure returns (uint256) {
        if (debtValue == 0) {
            return type(uint256).max;
        }
        return (collateralValue * 1e18) / (debtValue * 200);
    }

    /// @notice Calculate interest rate based on utilization
    function calculateInterestRate(uint256 utilization) public pure returns (uint256) {
        if (utilization < 80) {
            return 5; // Base rate 5%
        } else {
            return 10 + (utilization - 80); // Dynamic increase
        }
    }

    /// @notice Pause the protocol
    function pauseProtocol() external onlyAdmin {
        paused = true;
    }

    /// @notice Unpause the protocol
    function unpauseProtocol() external onlyAdmin {
        paused = false;
    }

    /// @notice Emergency withdrawal for the admin
    function emergencyWithdraw(uint256 amount) external onlyAdmin {
        require(amount <= lstToken.balanceOf(address(this)), "Insufficient funds");
        require(lstToken.transfer(msg.sender, amount), "Transfer failed");
    }

    /// @notice Set the treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        treasury = _treasury;
    }

    /// @notice Set the minimum health factor for liquidation
    function setMinHealthFactor(uint256 _minHealthFactor) external onlyAdmin {
        minHealthFactor = _minHealthFactor;
    }

    /// @notice Set the cooldown period for borrowing
    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyAdmin {
        borrowCooldown = _cooldownPeriod;
    }

    /// @notice Fallback mechanism to recover failed oracle data
    function recoverOracleData() external view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) {
            revert("Oracle data is invalid");
        }
        return price;
    }
}
