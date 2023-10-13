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
/// @title KPI tokens manager make immutable test
/// @dev Tests KPI tokens manager immutability setting.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract KpiTokensManagerMakeImmutableTest is BaseTestSetup {
    function testNotOwner() external {
        KPITokensManager _manager = initializeKPITokensManager(address(1));
        vm.prank(address(999)); // prank to non owner
        vm.expectRevert("Ownable: caller is not the owner");
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
        _manager.upgradeTo(address(_upgraded));
    }
}
