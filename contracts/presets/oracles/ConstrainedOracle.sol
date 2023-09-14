pragma solidity >=0.8.0;

import {Initializable} from "oz-upgradeable/proxy/utils/Initializable.sol";
import {BaseOracle} from "./BaseOracle.sol";
import {InitializeOracleParams} from "../../commons/Types.sol";
import {IKPIToken} from "../../interfaces/kpi-tokens/IKPIToken.sol";
import {UNIT, INVALID_ANSWER} from "../../commons/Constants.sol";

enum Constraint {
    Between,
    NotBetween,
    // range is very similar to between, except the final completion
    // percentage is determined based on the final absolute result
    // checking where it landed in the specified range. As an example,
    // if we have a range constraint with bounds 0 and 10 and the end
    // result is 5, the goal will be determined to have been 50% completed.
    Range,
    GreaterThan,
    LowerThan,
    Equal,
    NotEqual
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ConstrainedOracle contract
/// @dev An oracle preset that can be initialized with a
/// constraint on the end result and that transforms the end
/// result itself in a Carrot-compatible target completion
/// percentage based on it on finalization.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
abstract contract ConstrainedOracle is Initializable {
    uint256 internal constant MULTIPLIER = 64;

    Constraint internal constraint;
    uint256 internal value0;
    uint256 internal value1;

    error InvalidConstraint();
    error InvalidValues();
    error InvalidRangeBounds();
    error InvalidGreaterThanConstraintValue();
    error InvalidLowerThanConstraintValue();

    /// @dev Sets up the constraint on the end result of the oracle based on
    /// the given parameters. This function can only be called while initializing
    /// an oracle instance. If you extend from this contract, make sure you call this,
    /// otherwise no state will be initialized.
    /// @param _constraint The oracle's constraint type.
    /// @param _value0 The first value that can be used, in tandem with the constraint type, to specify
    /// the required constraint. This is always required.
    /// @param _value1 The second value that can be used, in tandem with the constraint type, to specify
    /// the required constraint. This is only valid for constraint types that need a range to be applied,
    /// such as "between", "not between" and "range".
    function __ConstrainedOracle_init(Constraint _constraint, uint256 _value0, uint256 _value1)
        internal
        onlyInitializing
    {
        (value0, value1) = _validateConstraint(_constraint, _value0, _value1);
        constraint = _constraint;
    }

    /// @dev Checks that the user-given constraint is sane and valid.
    /// @param _constraint The constraint type.
    /// @param _value0 The first value that can be used, in tandem with the constraint type, to specify
    /// the required constraint. This is always required.
    /// @param _value1 The second value that can be used, in tandem with the constraint type, to specify
    /// the required constraint. This is only valid for constraint types that need a range to be applied,
    /// such as "between", "not between" and "range".
    function _validateConstraint(Constraint _constraint, uint256 _value0, uint256 _value1)
        private
        pure
        returns (uint256, uint256)
    {
        if (_value0 == INVALID_ANSWER || _value1 == INVALID_ANSWER) revert InvalidValues();

        if (
            _constraint == Constraint.Between || _constraint == Constraint.NotBetween || _constraint == Constraint.Range
        ) {
            if (_value1 <= _value0) {
                revert InvalidRangeBounds();
            }
            return (_value0, _value1);
        }

        if (_constraint == Constraint.GreaterThan) {
            if (_value0 >= INVALID_ANSWER - 1) {
                revert InvalidGreaterThanConstraintValue();
            }
            return (_value0, 0);
        }

        if (_constraint == Constraint.LowerThan) {
            if (_value0 == 0) {
                revert InvalidLowerThanConstraintValue();
            }
            return (_value0, 0);
        }

        if (_constraint == Constraint.Equal || _constraint == Constraint.NotEqual) {
            // no extra validation is required for the "equal" and "not equal" constraints
            // as the only invalid value would be the invalid answer one, which is covered above
            return (_value0, 0);
        }

        // we should never arrive here
        revert InvalidConstraint();
    }

    /// @dev The main function exposed by the oracle preset. This can be used by implementations at
    /// finalization time to transform the final value of the oracle to a Carrot-compatible goal
    /// completion percentage taking into account the constraint.
    /// @param _result The final value of the oracle.
    function _toCompletionPercentage(uint256 _result) internal view returns (uint256) {
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
                uint256 _numerator = ((_result - _value0) * UNIT) << MULTIPLIER;
                uint256 _denominator = _value1 - _value0;
                return (_numerator / _denominator) >> MULTIPLIER;
            }
        } else if (_constraint == Constraint.Between) {
            return _result > value0 && _result < value1 ? UNIT : 0;
        } else if (_constraint == Constraint.NotBetween) {
            return _result < value0 || _result > value1 ? UNIT : 0;
        } else if (_constraint == Constraint.GreaterThan) {
            return _result > value0 ? UNIT : 0;
        } else if (_constraint == Constraint.LowerThan) {
            return _result < value0 ? UNIT : 0;
        } else if (_constraint == Constraint.Equal) {
            return _result == value0 ? UNIT : 0;
        } else if (_constraint == Constraint.NotEqual) {
            return _result != value0 ? UNIT : 0;
        } else {
            // we should never arrive here
            revert InvalidConstraint();
        }
    }
}
