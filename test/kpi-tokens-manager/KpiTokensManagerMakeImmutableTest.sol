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
/// @title KPI tokens manager make immutable test
/// @dev Tests KPI tokens manager immutability setting.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerMakeImmutableTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensManager _manager = initializeKPITokensManager(address(1));
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
        _manager.makeImmutable();
    }

    function testSuccess() external {
        KPITokensManager _manager = initializeKPITokensManager(address(1));
        assertFalse(_manager.disallowUpgrades());
        vm.prank(_manager.owner());
        _manager.makeImmutable();
        assertTrue(_manager.disallowUpgrades());
        UpgradedKPITokensManager _upgraded = new UpgradedKPITokensManager();
        vm.expectRevert(abi.encodeWithSignature("Immutable()"));
        _manager.upgradeToAndCall(address(_upgraded), abi.encode(""));
    }
}
