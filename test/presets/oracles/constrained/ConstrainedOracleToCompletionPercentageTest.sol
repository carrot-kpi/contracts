pragma solidity 0.8.23;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockConstrainedOracle} from "../../../mocks/MockConstrainedOracle.sol";
import {IOraclesManager} from "../../../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Constraint} from "../../../../contracts/presets/oracles/ConstrainedOracle.sol";
import {InitializeOracleParams} from "../../../../contracts/commons/Types.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {INVALID_ANSWER, UNIT} from "../../../../contracts/commons/Constants.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Constrained oracle preset to completion percentage test
/// @dev Tests the to completion percentage function in the constrained oracle preset.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract ConstrainedOracleToCompletionPercentageTest is BaseTestSetup {
    function initializeConstrainedOracle(Constraint _constraint, uint256 _value0, uint256 _value1)
        internal
        returns (MockConstrainedOracle)
    {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(Clones.clone(address(mockConstrainedOracleTemplate)));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(_constraint, _value0, _value1)
            })
        );
        return oracleInstance;
    }

    function testInvalidAnswer() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Equal, 1, 0);
        assertEq(oracleInstance.toCompletionPercentage(INVALID_ANSWER), INVALID_ANSWER);
    }

    function testBetweenConstraintBelowLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Between, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(9), 0);
    }

    function testBetweenConstraintAtLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Between, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testBetweenConstraintInRange() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Between, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(16), UNIT);
    }

    function testBetweenConstraintAtUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Between, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(20), 0);
    }

    function testBetweenConstraintAboveUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Between, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(40), 0);
    }

    function testNotBetweenConstraintBelowLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotBetween, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(9), UNIT);
    }

    function testNotBetweenConstraintAtLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotBetween, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testNotBetweenConstraintInRange() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotBetween, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(16), 0);
    }

    function testNotBetweenConstraintAtUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotBetween, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(20), 0);
    }

    function testNotBetweenConstraintAboveUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotBetween, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(40), UNIT);
    }

    function testRangeConstraintBelowLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Range, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(9), 0);
    }

    function testRangeConstraintAtLowerBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Range, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testRangeConstraintInRange() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Range, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(16), 600_000);
    }

    function testRangeConstraintAtUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Range, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(20), UNIT);
    }

    function testRangeConstraintAboveUpperBound() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Range, 10, 20);
        assertEq(oracleInstance.toCompletionPercentage(40), UNIT);
    }

    function testGreaterThanConstraintLessThanTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.GreaterThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(9), 0);
    }

    function testGreaterThanConstraintAtTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.GreaterThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testGreaterThanConstraintAboveTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.GreaterThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(20), UNIT);
    }

    function testLowerThanConstraintMoreThanTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.LowerThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(11), 0);
    }

    function testLowerThanConstraintAtTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.LowerThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testLowerThanConstraintBelowTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.LowerThan, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(7), UNIT);
    }

    function testEqualConstraintBelowTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Equal, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(7), 0);
    }

    function testEqualConstraintAtTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Equal, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(10), UNIT);
    }

    function testEqualConstraintAboveTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.Equal, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(12), 0);
    }

    function testNotEqualConstraintBelowTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotEqual, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(7), UNIT);
    }

    function testNotEqualConstraintAtTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotEqual, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(10), 0);
    }

    function testNotEqualConstraintAboveTarget() external {
        MockConstrainedOracle oracleInstance = initializeConstrainedOracle(Constraint.NotEqual, 10, 0);
        assertEq(oracleInstance.toCompletionPercentage(12), UNIT);
    }
}
