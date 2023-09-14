pragma solidity >=0.8.0;

import {IOraclesManager1} from "../oracles-managers/IOraclesManager1.sol";
import {InitializeOracleParams} from "../../commons/Types.sol";
import {Template} from "../IBaseTemplatesManager.sol";
import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {IKPIToken} from "../kpi-tokens/IKPIToken.sol";
import {IOracle} from "./IOracle.sol";

enum Constraint {
    Between,
    // range is very similar to between, except the final completion
    // percentage is determined based on the final absolute result
    // checking where it landed in the specified range. As an example,
    // if we have a range constraint with bounds 0 and 10 and the end
    //  result is 5, the goal will be determined to have been 50% completed.
    Range,
    GreaterThan,
    LowerThan,
    Equal
}

// TODO: add tests and proper natspec

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ConstrainedOracle contract
/// @dev An oracle contract that can be initialized with a
/// constraint on the end result and that transforms the end
/// result itself in a Carrot-compatible target completion
/// percentage based on it on finalization.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
abstract contract ConstrainedOracle is IOracle, Initializable {
    uint256 internal constant INVALID_ANSWER = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant MULTIPLIER = 64;
    uint256 internal constant UNIT = 1_000_000;

    bool public finalized;
    address public kpiToken;
    address internal oraclesManager;
    uint128 internal templateVersion;
    uint256 internal templateId;
    Constraint internal constraint;
    uint256 internal value0;
    uint256 internal value1;

    error Forbidden();
    error ZeroAddressKPIToken();
    error InvalidTemplateId();
    error InvalidTemplateVersion();
    error InvalidConstraint();
    error InvalidValues();
    error InvalidBetweenConstraintValues();
    error InvalidGreaterThanConstraintValue();
    error InvalidLowerThanConstraintValue();

    event Finalize(uint256 result);

    function __ConstrainedOracle_init(
        address _kpiToken,
        uint256 _templateId,
        uint128 _templateVersion,
        Constraint _constraint,
        uint256 _value0,
        uint256 _value1
    ) internal onlyInitializing {
        if (_kpiToken == address(0)) revert ZeroAddressKPIToken();
        if (_templateId == 0) revert InvalidTemplateId();
        if (_templateVersion == 0) revert InvalidTemplateVersion();

        if (_value0 == INVALID_ANSWER || _value1 == INVALID_ANSWER) revert InvalidValues();

        if (_constraint == Constraint.Between || _constraint == Constraint.Range) {
            if (_value1 <= _value0) {
                revert InvalidBetweenConstraintValues();
            }
        } else if (_constraint == Constraint.GreaterThan) {
            if (_value0 >= INVALID_ANSWER - 1) {
                revert InvalidGreaterThanConstraintValue();
            }
        } else if (_constraint == Constraint.LowerThan) {
            if (_value0 == 0) {
                revert InvalidLowerThanConstraintValue();
            }
        } else if (_constraint == Constraint.Equal) {
            // no extra validation is required for the "equal" constraint as the only invalid
            // value would be the invalid answer one, which is covered above
        } else {
            // we should never arrive here
            revert InvalidConstraint();
        }

        kpiToken = _kpiToken;
        oraclesManager = msg.sender;
        templateId = _templateId;
        templateVersion = _templateVersion;
        constraint = _constraint;
        value0 = _value0;
        value1 = _value1;
    }

    function _finalize(uint256 _result) internal {
        if (finalized) revert Forbidden();
        finalized = true;
        uint256 _completionPercentage = _resultToCompletionPercentage(_result);
        IKPIToken(kpiToken).finalize(_completionPercentage);
        emit Finalize(_result);
    }

    function _resultToCompletionPercentage(uint256 _result) internal view returns (uint256) {
        if (_result == INVALID_ANSWER) {
            return INVALID_ANSWER;
        }

        Constraint _constraint = constraint;
        if (_constraint == Constraint.Range) {
            uint256 _value0 = value0;
            uint256 _value1 = value1;
            if (_result <= _value0) return 0;
            if (_result >= _value1) {
                return UNIT;
            } else {
                uint256 _numerator = (_result - _value0 * UNIT) << MULTIPLIER;
                uint256 _denominator = _value1 - _value0;
                return (_numerator / _denominator) >> MULTIPLIER;
            }
        } else if (_constraint == Constraint.Between) {
            return _result >= value0 && _result <= value0 ? UNIT : 0;
        } else if (_constraint == Constraint.GreaterThan) {
            return _result > value0 ? UNIT : 0;
        } else if (_constraint == Constraint.LowerThan) {
            return _result < value0 ? UNIT : 0;
        } else if (_constraint == Constraint.Equal) {
            return _result == value0 ? UNIT : 0;
        } else {
            // we should never arrive here
            revert InvalidConstraint();
        }
    }
}
