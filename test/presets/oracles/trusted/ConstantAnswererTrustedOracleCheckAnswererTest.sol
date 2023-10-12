pragma solidity 0.8.19;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockConstantAnswererTrustedOracle} from "../../../mocks/MockConstantAnswererTrustedOracle.sol";
import {IOraclesManager} from "../../../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Constraint} from "../../../../contracts/presets/oracles/ConstrainedOracle.sol";
import {InitializeOracleParams} from "../../../../contracts/commons/Types.sol";
import {ClonesUpgradeable} from "oz-upgradeable/proxy/ClonesUpgradeable.sol";
import {INVALID_ANSWER} from "../../../../contracts/commons/Constants.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Constant answerer trusted oracle preset initialize test
/// @dev Tests the check answerer function in the constant answerer trusted oracle.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ConstantAnswererTrustedOracleCheckAnswererTest is BaseTestSetup {
    function initializeOracle(address _answerer) internal returns (MockConstantAnswererTrustedOracle) {
        MockConstantAnswererTrustedOracle oracleInstance = new MockConstantAnswererTrustedOracle(_answerer);
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode()
            })
        );
        return oracleInstance;
    }

    function testWrongAnswerer() external {
        MockConstantAnswererTrustedOracle oracleInstance = initializeOracle(address(1));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vm.prank(address(2));
        oracleInstance.checkAnswerer();
    }

    function testSuccess() external {
        MockConstantAnswererTrustedOracle oracleInstance = initializeOracle(address(1));
        vm.prank(address(1));
        oracleInstance.checkAnswerer();
    }
}
