pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradedKPITokensFactory is KPITokensFactory {
    function isUpgraded() external pure returns (bool) {
        return true;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Factory upgrade test
/// @dev Tests factory upgrades.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract FactoryUpgradeTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        _factory.upgradeToAndCall(address(1234), abi.encode());
    }

    function testNonUUPSCompliantImplementationContract() external {
        KPITokensFactory _factory = initializeKPITokensFactory(address(1), address(2), address(3));
        vm.prank(_factory.owner());
        vm.expectRevert();
        _factory.upgradeToAndCall(address(1234), abi.encode());
    }

    function testSuccess() external {
        address _kpiTokensManager = address(1);
        address _oraclesManager = address(2);
        address _feeReceiver = address(3);
        KPITokensFactory _factory = initializeKPITokensFactory(_kpiTokensManager, _oraclesManager, _feeReceiver);
        assertEq(_factory.kpiTokensManager(), _kpiTokensManager);
        assertEq(_factory.oraclesManager(), _oraclesManager);
        assertEq(_factory.feeReceiver(), _feeReceiver);
        vm.expectRevert();
        UpgradedKPITokensFactory(address(_factory)).isUpgraded();

        vm.prank(_factory.owner());
        _factory.upgradeToAndCall(address(new UpgradedKPITokensFactory()), abi.encode());
        UpgradedKPITokensFactory _upgraded = UpgradedKPITokensFactory(address(_factory));
        assertTrue(_upgraded.isUpgraded());
    }
}
