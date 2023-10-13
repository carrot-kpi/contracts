pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradedOraclesManager is OraclesManager {
    function isUpgraded() external pure returns (bool) {
        return true;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager make immutable test
/// @dev Tests oracles manager immutability setting.
/// @author Federico Luzzi - <federico.luzzi@carrot-labs.xyz>
contract OraclesManagerMakeImmutableTest is BaseTestSetup {
    function testNotOwner() external {
        OraclesManager _manager = initializeOraclesManager(address(1));
        vm.prank(address(999)); // prank to non owner
        vm.expectRevert("Ownable: caller is not the owner");
        _manager.makeImmutable();
    }

    function testSuccess() external {
        OraclesManager _manager = initializeOraclesManager(address(1));
        assertFalse(_manager.disallowUpgrades());
        vm.prank(_manager.owner());
        _manager.makeImmutable();
        assertTrue(_manager.disallowUpgrades());
        UpgradedOraclesManager _upgraded = new UpgradedOraclesManager();
        vm.expectRevert(abi.encodeWithSignature("Immutable()"));
        _manager.upgradeTo(address(_upgraded));
    }
}
