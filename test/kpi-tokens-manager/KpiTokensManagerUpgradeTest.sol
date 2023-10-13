pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

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
        vm.prank(address(999)); // prank to non owner
        vm.expectRevert("Ownable: caller is not the owner");
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
        _manager.upgradeTo(address(new UpgradedKPITokensManager()));
        UpgradedKPITokensManager _upgraded = UpgradedKPITokensManager(address(_manager));
        assertTrue(_upgraded.isUpgraded());
    }
}
