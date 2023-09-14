pragma solidity 0.8.19;

import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {BaseOracle} from "./BaseOracle.sol";
import {IOracle} from "../../interfaces/oracles/IOracle.sol";
import {IKPIToken} from "../../interfaces/kpi-tokens/IKPIToken.sol";
import {IBaseTemplatesManager, Template} from "../../interfaces/IBaseTemplatesManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Constant answerer trusted oracle
/// @dev A base oracle template implementation that allows an external predefined and constant
/// answerer to finalize the oracle when it decides the time has come.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
abstract contract ConstantAnswererTrustedOracle {
    address public immutable answerer;

    error Forbidden();
    error ZeroAddressAnswerer();

    /// @dev Sets the trusted answerer.
    /// @param _answerer The address of the account that will be allowed to finalize
    /// the oracle (should be chosen with care as it's immutable).
    constructor(address _answerer) {
        if (_answerer == address(0)) revert ZeroAddressAnswerer();
        answerer = _answerer;
    }

    /// @dev The main function exposed by the oracle preset. This can be used by implementations at
    /// finalization time to check that any external party submitting an answer is the trusted
    /// answerer set up at construction time.
    function _checkAnswerer() internal view {
        if (msg.sender != answerer) revert Forbidden();
    }
}
