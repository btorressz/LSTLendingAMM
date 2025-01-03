# LSTLendingAMM
#  **LST Lending AMM with Collateralized Swaps (Ethereum Solidity Version)**

This project is the **Ethereum Solidity version** of a lending protocol originally implemented on **Solana using Rust and Anchor**. The protocol(smart contract) has been carefully adapted to the Ethereum ecosystem, leveraging Solidity, OpenZeppelin libraries, and Chainlink oracles to ensure secure and efficient lending operations.

## 🚀 **Project Overview**

**LST Lending AMM** is a decentralized lending protocol built on Ethereum that allows users to:
- Deposit Liquid Staked Tokens (LST) as collateral.
- Borrow assets against their collateralized LST holdings.
- Participate in the liquidation of under-collateralized positions for incentives.

This protocol(smart contract) ensures secure lending, dynamic interest rates, and proper risk management through collateralization ratios and real-time oracle price feeds.

---

## 📝 **Key Features**

### ✅ **Collateral Deposit**
- Users can deposit LST tokens as collateral to secure their borrowings.

### ✅ **Asset Borrowing**
- Borrow assets based on collateral value with dynamically calculated interest rates.

### ✅ **Liquidation Mechanism**
- Liquidators can liquidate under-collateralized positions and earn a liquidation bonus.

### ✅ **Dynamic Interest Rates**
- Interest rates are determined based on pool utilization.

### ✅ **Oracle Price Feeds**
- Real-time price data is fetched from Chainlink Oracles to ensure accurate collateral valuation.

### ✅ **Role-Based Access Control**
- **Admin Role:** Protocol management and critical settings.
- **Liquidator Role:** Permission to liquidate unsafe positions.

### ✅ **Emergency Mechanisms**
- Admins can pause/unpause protocol operations.
- Emergency withdrawal for critical fund recovery.

---

## 🛠️ **Core Functionalities**

### 🔹 **Deposit Collateral**
- Users deposit LST tokens as collateral for borrowing.

### 🔹 **Borrow Tokens**
- Borrow tokens are provided based on a collateralization ratio (default 200%).

### 🔹 **Liquidate Positions**
- Liquidators can repay unsafe borrow positions and receive liquidation bonuses.

### 🔹 **Protocol Pause/Unpause**
- Admins can halt protocol operations during emergencies.

### 🔹 **Dynamic Risk Parameters**
- Admins can adjust:
  - **Health Factor Threshold**
  - **Cooldown Period for Borrowing**
  - **Treasury Address**

---

## 📊 **Smart Contract Parameters**

- **Collateralization Ratio:** Default 200%  
- **Minimum Health Factor:** `1e18`  
- **Borrow Cooldown Period:** `1 day`  
- **Liquidation Bonus:** 1%  
- **Treasury Fee:** 10%  

---

## 🔑 **Roles and Permissions**

### 👑 **Admin Role**
- Pause/Unpause protocol.
- Update treasury address.
- Adjust health factor and cooldown period.
- Emergency fund withdrawal.

### 🛡️ **Liquidator Role**
- Perform liquidation on under-collateralized positions.

---

## 🔗 **Dependencies**

- **OpenZeppelin Contracts:** AccessControl, ReentrancyGuard, IERC20.
- **Chainlink Price Feeds:** Real-time price updates for accurate valuations.

---

## 🧪 **Testing**

### 📌 **Basic Scenarios:**
1. **Collateral Deposit:** Verify successful collateral deposit.
2. **Asset Borrowing:** Ensure borrowing respects collateralization requirements.
3. **Liquidation:** Test under-collateralized liquidation scenarios.
4. **Protocol Pause:** Validate the protocol pause/unpause functionality.

### 📌 **Edge Cases:**
- Borrow attempts during cooldown periods.
- Invalid oracle price feed data.
- Emergency withdrawal edge scenarios.

---
