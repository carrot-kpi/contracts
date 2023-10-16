pragma solidity 0.8.21;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {ERC1967Proxy} from "oz/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "oz-upgradeable/access/OwnableUpgradeable.sol";

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
        address _pranked = address(999);
        vm.prank(_pranked); // prank to non owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _pranked));
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
        _manager.upgradeToAndCall(address(_upgraded), abi.encode(""));
    }
}
