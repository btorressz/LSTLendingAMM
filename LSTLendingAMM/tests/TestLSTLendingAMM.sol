// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "contracts/LSTLendingAMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Test Contract for LSTLendingAMM
/// @notice A simple test suite for interacting with LSTLendingAMM on Remix IDE
contract TestLSTLendingAMM {
    LSTLendingAMM public lendingContract;
    MockToken public lstToken;
    MockToken public borrowToken;

    address public admin;
    address public user1;
    address public liquidator;

    /// @notice Deploy mock tokens and the lending contract
    constructor() {
        admin = msg.sender;
        user1 = address(0x123);
        liquidator = address(0x456);

        // Deploy mock tokens
        lstToken = new MockToken("LST Token", "LST");
        borrowToken = new MockToken("Borrow Token", "BRW");

        // Mint initial tokens
        lstToken.mint(admin, 10000 * 1e18);
        borrowToken.mint(admin, 10000 * 1e18);

        // Deploy lending contract
        lendingContract = new LSTLendingAMM(
            address(lstToken),
            address(borrowToken),
            address(0x0), // Mock Oracle (set a valid oracle address in practice)
            admin
        );

        // Approve lending contract for token transfers
        lstToken.approve(address(lendingContract), 10000 * 1e18);
        borrowToken.approve(address(lendingContract), 10000 * 1e18);
    }

    /// @notice Test deposit functionality
    function testDepositCollateral() public {
        uint256 depositAmount = 100 * 1e18;
        lstToken.mint(user1, depositAmount);
        lstToken.approve(address(lendingContract), depositAmount);
        
        lendingContract.depositCollateral(depositAmount);
    }

    /// @notice Test borrowing functionality
    function testBorrowAssets() public {
        uint256 borrowAmount = 50 * 1e18;
        lendingContract.borrow(borrowAmount);
    }

    /// @notice Test liquidation functionality
    function testLiquidatePosition() public {
        uint256 repayAmount = 20 * 1e18;
        lendingContract.liquidate(user1, repayAmount);
    }

    /// @notice Test protocol pause and unpause
    function testPauseProtocol() public {
        lendingContract.pauseProtocol();
        lendingContract.unpauseProtocol();
    }

    /// @notice Test emergency withdrawal
    function testEmergencyWithdraw() public {
        uint256 withdrawAmount = 10 * 1e18;
        lendingContract.emergencyWithdraw(withdrawAmount);
    }
}

/// @title MockToken for Testing Purposes
/// @notice Simple ERC20 token for testing
contract MockToken is ERC20 {
    address public admin;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }
}
