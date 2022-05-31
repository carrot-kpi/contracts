pragma solidity >=0.8.0;

import {IERC20Upgradeable} from "oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IKPIToken} from "./IKPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Aave ERC20 interface
/// @dev Interface for the Aave ERC20 contract.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
interface IAaveERC20KPIToken is IKPIToken, IERC20Upgradeable {
    struct OracleData {
        uint256 id;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 weight;
        bytes data;
    }

    struct InputCollateral {
        address token;
        uint256 amount;
        uint256 minimumPayout;
    }

    struct Collateral {
        address aToken;
        address underlyingToken;
        uint256 minimumPayout;
    }

    struct FinalizableOracle {
        address addrezz;
        bool finalized;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 finalProgress;
        uint256 weight;
    }

    struct RedeemedCollateral {
        address token;
        uint256 amount;
    }
}
