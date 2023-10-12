pragma solidity 0.8.19;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {MockBaseOracle} from "../../../mocks/MockBaseOracle.sol";
import {IOraclesManager} from "../../../../contracts/interfaces/IOraclesManager.sol";
import {Template} from "../../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {InitializeOracleParams} from "../../../../contracts/commons/Types.sol";
import {ClonesUpgradeable} from "oz-upgradeable/proxy/ClonesUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Base oracle preset initialize test
/// @dev Tests initialization in base oracle preset.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract BaseOracleInitializationTest is BaseTestSetup {
    function testZeroAddressKpiToken() external {
        MockBaseOracle oracleInstance = MockBaseOracle(ClonesUpgradeable.clone(address(mockBaseOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("ZeroAddressKPIToken()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(0),
                templateId: 1,
                templateVersion: 1,
                data: abi.encode(uint256(1))
            })
        );
    }

    function testZeroTemplateId() external {
        MockBaseOracle oracleInstance = MockBaseOracle(ClonesUpgradeable.clone(address(mockBaseOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateId()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 0,
                templateVersion: 1,
                data: abi.encode()
            })
        );
    }

    function testZeroVersion() external {
        MockBaseOracle oracleInstance = MockBaseOracle(ClonesUpgradeable.clone(address(mockBaseOracleTemplate)));
        vm.expectRevert(abi.encodeWithSignature("InvalidTemplateVersion()"));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: address(1),
                templateId: 1,
                templateVersion: 0,
                data: abi.encode()
            })
        );
    }

    function testSuccess() external {
        MockBaseOracle oracleInstance = MockBaseOracle(ClonesUpgradeable.clone(address(mockBaseOracleTemplate)));
        Template memory _template = oraclesManager.template(1);
        address kpiToken = address(1);
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: kpiToken,
                templateId: _template.id,
                templateVersion: _template.version,
                data: abi.encode()
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), kpiToken);
        assertEq(oracleInstance.template().addrezz, _template.addrezz);
        assertEq(oracleInstance.template().id, _template.id);
        assertEq(oracleInstance.template().version, _template.version);
        assertEq(oracleInstance.template().specification, _template.specification);
    }

    function testFuzzSuccess(address _kpiToken, uint256 _templateId, uint128 _templateVersion, bytes memory _data)
        external
    {
        vm.assume(_kpiToken != address(0));
        vm.assume(_templateId != 0);
        vm.assume(_templateVersion != 0);

        MockBaseOracle oracleInstance = MockBaseOracle(ClonesUpgradeable.clone(address(mockBaseOracleTemplate)));
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            InitializeOracleParams({
                creator: address(this),
                kpiToken: _kpiToken,
                templateId: _templateId,
                templateVersion: _templateVersion,
                data: _data
            })
        );

        assertEq(oracleInstance.finalized(), false);
        assertEq(oracleInstance.kpiToken(), _kpiToken);
    }
}
