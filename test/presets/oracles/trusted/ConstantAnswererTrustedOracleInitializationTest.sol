pragma solidity 0.8.23;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockConstantAnswererTrustedOracle} from "../../../mocks/MockConstantAnswererTrustedOracle.sol";
import {IOraclesManager} from "../../../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Constraint} from "../../../../contracts/presets/oracles/ConstrainedOracle.sol";
import {InitializeOracleParams} from "../../../../contracts/commons/Types.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {INVALID_ANSWER} from "../../../../contracts/commons/Constants.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Constant answerer trusted oracle preset initialization test
/// @dev Tests initialization in the constant answerer trusted oracle preset.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract ConstantAnswererTrustedOracleInitializationTest is BaseTestSetup {
    function testZeroAddressAnswerer() external {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressAnswerer()"));
        new MockConstantAnswererTrustedOracle(address(0));
    }

    function testZeroAddressKpiToken() external {
        MockConstantAnswererTrustedOracle oracleInstance =
            MockConstantAnswererTrustedOracle(Clones.clone(address(mockConstantAnswererTrustedOracle)));
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
        MockConstantAnswererTrustedOracle oracleInstance =
            MockConstantAnswererTrustedOracle(Clones.clone(address(mockConstantAnswererTrustedOracle)));
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
        MockConstantAnswererTrustedOracle oracleInstance =
            MockConstantAnswererTrustedOracle(Clones.clone(address(mockConstantAnswererTrustedOracle)));
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
}
