pragma solidity 0.8.19;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockConstrainedOracle} from "../../../mocks/MockConstrainedOracle.sol";
import {IOraclesManager1} from "../../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Constraint} from "../../../../contracts/presets/oracles/ConstrainedOracle.sol";
import {InitializeOracleParams} from "../../../../contracts/commons/Types.sol";
import {ClonesUpgradeable} from "oz-upgradeable/proxy/ClonesUpgradeable.sol";
import {INVALID_ANSWER} from "../../../../contracts/commons/Constants.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Constrained oracle preset initialize test
/// @dev Tests initialization in constrained oracle preset.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ConstrainedOracleInitializationTest is BaseTestSetup {
    function testZeroAddressKpiToken() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressKPIToken()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(0),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Equal, 1, 0)
            })
        );
    }

    function testZeroTemplateId() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateId()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 0,
                templateVersion: 1,
                data: abi.encode(Constraint.Equal, 1, 0)
            })
        );
    }

    function testZeroVersion() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateVersion()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 0,
                data: abi.encode(Constraint.Equal, 1, 0)
            })
        );
    }

    function testValue0Invalid() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidValues()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Equal, INVALID_ANSWER, 0)
            })
        );
    }

    function testValue1Invalid() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidValues()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Equal, 0, INVALID_ANSWER)
            })
        );
    }

    function testBothValuesInvalid() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidValues()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Equal, INVALID_ANSWER, INVALID_ANSWER)
            })
        );
    }

    function testInvalidConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        // the error is an enum conversion one, so we do no data matching
        vm.expectRevert();
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 0,
                data: abi.encode(uint256(100_000), 1, 0)
            })
        );
    }

    function testBetweenConstraintInvalidRange() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));

        // lower bound == higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Between, 10, 10)
            })
        );

        // lower bound > higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Between, 11, 10)
            })
        );
    }

    function testNotBetweenConstraintInvalidRange() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));

        // lower bound == higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.NotBetween, 10, 10)
            })
        );

        // lower bound > higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.NotBetween, 11, 10)
            })
        );
    }

    function testRangeConstraintInvalidRange() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));

        // lower bound == higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Range, 10, 10)
            })
        );

        // lower bound > higher bound
        vm.expectRevert(abi.encodeWithSignature("InvalidRangeBounds()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.Range, 11, 10)
            })
        );
    }

    function testGreaterThanConstraintInvalidValue() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));

        vm.expectRevert(abi.encodeWithSignature("InvalidGreaterThanConstraintValue()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.GreaterThan, INVALID_ANSWER - 1, 0)
            })
        );
    }

    function testLowerThanConstraintInvalidValue() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));

        vm.expectRevert(abi.encodeWithSignature("InvalidLowerThanConstraintValue()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(Constraint.LowerThan, 0, 0)
            })
        );
    }

    function testSuccessBetweenConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(Constraint.Between, 0, 1)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.Between));
        assertEq(_value0, 0);
        assertEq(_value1, 1);
    }

    function testSuccessRangeConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(Constraint.Range, 0, 1)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.Range));
        assertEq(_value0, 0);
        assertEq(_value1, 1);
    }

    function testSuccessGreaterThanConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(Constraint.GreaterThan, 10_000, 0)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.GreaterThan));
        assertEq(_value0, 10_000);
        assertEq(_value1, 0);
    }

    function testSuccessLowerThanConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(Constraint.LowerThan, 20_000, 0)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.LowerThan));
        assertEq(_value0, 20_000);
        assertEq(_value1, 0);
    }

    function testSuccessEqualConstraint() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode(Constraint.Equal, 40_000, 0)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.Equal));
        assertEq(_value0, 40_000);
        assertEq(_value1, 0);
    }

    function testSuccessSingleValueConstraintDoubleValueProvided() external {
        MockConstrainedOracle oracleInstance =
            MockConstrainedOracle(ClonesUpgradeable.clone(address(mockConstrainedOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                // 2 values provided below
                data: abi.encode(Constraint.Equal, 40_000, 1)
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);

        (Constraint _constraint, uint256 _value0, uint256 _value1) =
            abi.decode(oracleInstance.data(), (Constraint, uint256, uint256));
        assertEq(uint256(_constraint), uint256(Constraint.Equal));
        // only one value set here
        assertEq(_value0, 40_000);
        assertEq(_value1, 0);
    }
}
