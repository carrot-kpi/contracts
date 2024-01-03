pragma solidity 0.8.23;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradedKPITokensManager is KPITokensManager {
    function isUpgraded() external pure returns (bool) {
        return true;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager upgrade test
/// @dev Tests KPI tokens manager upgrades.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KPITokensManagerUpgradeTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensManager _manager = initializeKPITokensManager(address(1));
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        _manager.upgradeToAndCall(address(1234), abi.encode());
    }

    function testNonUUPSCompliantImplementationContract() external {
        KPITokensManager _manager = initializeKPITokensManager(address(1));
        vm.prank(_manager.owner());
        vm.expectRevert();
        _manager.upgradeToAndCall(address(1234), abi.encode());
    }

    function testSuccess() external {
        address _factory = address(1);
        KPITokensManager _manager = initializeKPITokensManager(_factory);
        assertEq(_manager.factory(), _factory);
        vm.expectRevert();
        UpgradedKPITokensManager(address(_manager)).isUpgraded();

        vm.prank(_manager.owner());
        _manager.upgradeToAndCall(address(new UpgradedKPITokensManager()), abi.encode());
        UpgradedKPITokensManager _upgraded = UpgradedKPITokensManager(address(_manager));
        assertTrue(_upgraded.isUpgraded());
    }
}
