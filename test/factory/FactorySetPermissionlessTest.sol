pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {TokenAmount} from "../../contracts/commons/Types.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {OracleData, MockKPIToken} from "../mocks/MockKPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory set permissionless test
/// @dev Tests KPI token facotry's permissionlessness setting.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactorySetPermissionlessTest is BaseTestSetup {
    function testDefaultValue() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        assertFalse(_factory.permissionless());
    }

    function testNotOwner() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        assertFalse(_factory.permissionless());
        address _pranked = address(999);
        vm.prank(_pranked);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        _factory.setPermissionless(true);
        assertFalse(_factory.permissionless());
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        _factory.createToken(1, "foo", block.timestamp + 10, abi.encode("foo"), abi.encode("bar"));
    }

    function testSuccess() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), feeReceiver);

        KPITokensManager _kpiTokensManager = initializeKPITokensManager(address(_factory));
        _kpiTokensManager.addTemplate(address(mockKpiTokenTemplate), "fake-kpi-token-spec");

        OraclesManager _oraclesManager = initializeOraclesManager(address(_factory));
        _oraclesManager.addTemplate(address(mockOracleTemplate), "fake-oracle-spec");
        _oraclesManager.addTemplate(address(mockBaseOracleTemplate), "fake-oracle-spec");
        _oraclesManager.addTemplate(address(mockConstrainedOracleTemplate), "fake-oracle-spec");
        _oraclesManager.addTemplate(address(mockConstantAnswererTrustedOracle), "fake-oracle-spec");

        _factory.setKpiTokensManager(address(_kpiTokensManager));
        _factory.setOraclesManager(address(_oraclesManager));

        assertFalse(_factory.permissionless());

        vm.prank(_factory.owner());
        _factory.setPermissionless(true);
        assertTrue(_factory.permissionless());

        string memory _description = "foo";
        MockKPIToken _kpiToken = createKpiTokenWithFactory(_factory, _description);
        assertEq(_kpiToken.description(), _description);
    }
}
